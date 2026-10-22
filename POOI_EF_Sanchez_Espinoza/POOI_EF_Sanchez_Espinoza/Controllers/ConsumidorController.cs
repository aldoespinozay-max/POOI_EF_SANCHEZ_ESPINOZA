using POOI_EF_Sanchez_Espinoza.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web.Mvc;

namespace POOI_EF_Sanchez_Espinoza.Controllers
{
    public class ConsumidorController : Controller
    {
        private string cadenaConexion = ConfigurationManager.ConnectionStrings["conexionADatos"].ConnectionString;

        IEnumerable<Consumidor> listarConsumidores()
        {
            List<Consumidor> lista = new List<Consumidor>();
            SqlConnection conexion = new SqlConnection(cadenaConexion);
            conexion.Open();
            SqlCommand comando = new SqlCommand("usp_listar_consumidor", conexion);
            comando.CommandType = CommandType.StoredProcedure;
            SqlDataReader lector = comando.ExecuteReader();
            while (lector.Read())
            {
                lista.Add(leerConsumidor(lector));
            }
            lector.Close();
            conexion.Close();
            return lista;
        }

        Consumidor leerConsumidor(SqlDataReader lector)
        {
            return new Consumidor
            {
                DniCont = lector.GetString(0).Trim(),
                NomCont = lector.GetString(1),
                ApeCont = lector.GetString(2),
                EmailCont = lector.IsDBNull(3) ? null : lector.GetString(3),
                IdPais = lector.IsDBNull(4) ? null : lector.GetString(4).Trim()
            };
        }

        Consumidor obtenerConsumidor(string dniCont)
        {
            Consumidor consumidor = null;
            SqlConnection conexion = new SqlConnection(cadenaConexion);
            conexion.Open();
            SqlCommand comando = new SqlCommand("usp_obtener_consumidor", conexion);
            comando.CommandType = CommandType.StoredProcedure;
            comando.Parameters.AddWithValue("@dnicont", dniCont);
            SqlDataReader lector = comando.ExecuteReader();
            if (lector.Read())
            {
                consumidor = leerConsumidor(lector);
            }
            lector.Close();
            conexion.Close();
            return consumidor;
        }

        string guardarConsumidor(Consumidor consumidor, string procedimiento)
        {
            string correo = string.IsNullOrWhiteSpace(consumidor.EmailCont)
                ? null
                : consumidor.EmailCont.Trim();
            SqlConnection conexion = new SqlConnection(cadenaConexion);
            conexion.Open();
            SqlCommand comando = new SqlCommand(procedimiento, conexion);
            comando.CommandType = CommandType.StoredProcedure;
            comando.Parameters.AddWithValue("@dnicont", consumidor.DniCont ?? "");
            comando.Parameters.AddWithValue("@nomcont", consumidor.NomCont ?? "");
            comando.Parameters.AddWithValue("@apecont", consumidor.ApeCont ?? "");
            SqlParameter parametroCorreo = comando.Parameters.Add("@emailcont", SqlDbType.VarChar, 250);
            parametroCorreo.Value = (object)correo ?? DBNull.Value;
            comando.Parameters.AddWithValue("@idpais", consumidor.IdPais ?? "");
            SqlParameter salida = comando.Parameters.Add("@mensaje", SqlDbType.VarChar, 100);
            salida.Direction = ParameterDirection.Output;
            comando.ExecuteNonQuery();
            conexion.Close();
            return salida.Value.ToString();
        }

        string eliminarConsumidor(string dniCont)
        {
            SqlConnection conexion = new SqlConnection(cadenaConexion);
            conexion.Open();
            SqlCommand comando = new SqlCommand("usp_eliminar_consumidor", conexion);
            comando.CommandType = CommandType.StoredProcedure;
            comando.Parameters.AddWithValue("@dnicont", dniCont);
            SqlParameter salida = comando.Parameters.Add("@mensaje", SqlDbType.VarChar, 100);
            salida.Direction = ParameterDirection.Output;
            comando.ExecuteNonQuery();
            conexion.Close();
            return salida.Value.ToString();
        }

        public ActionResult Index()
        {
            return View(listarConsumidores());
        }

        public ActionResult Create()
        {
            return View(new Consumidor());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(Consumidor consumidor)
        {
            ViewBag.Mensaje = guardarConsumidor(consumidor, "usp_agrega_consumidor");
            return View(consumidor);
        }

        public ActionResult Update(string id)
        {
            Consumidor consumidor = obtenerConsumidor(id);
            if (consumidor == null) return HttpNotFound();
            return View(consumidor);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Update(Consumidor consumidor)
        {
            ViewBag.Mensaje = guardarConsumidor(consumidor, "usp_actualizar_consumidor");
            return View(consumidor);
        }

        public ActionResult Delete(string id)
        {
            Consumidor consumidor = obtenerConsumidor(id);
            if (consumidor == null) return HttpNotFound();
            return View(consumidor);
        }

        [HttpPost]
        [ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmado(string id)
        {
            TempData["Mensaje"] = eliminarConsumidor(id);
            return RedirectToAction("Index");
        }
    }
}
