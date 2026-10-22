namespace POOI_EF_Sanchez_Espinoza.Models
{
    public class Consumidor
    {
        public string DniCont { get; set; }
        public string NomCont { get; set; }
        public string ApeCont { get; set; }
        public string EmailCont { get; set; }
        public string IdPais { get; set; }

        public Consumidor() { }

        public Consumidor(string dniCont, string nomCont, string apeCont,
            string emailCont, string idPais)
        {
            DniCont = dniCont;
            NomCont = nomCont;
            ApeCont = apeCont;
            EmailCont = emailCont;
            IdPais = idPais;
        }
    }
}
