namespace KAZABUILD.Domain.Enums
{
    /// <summary>
    /// Enum representing different types of ports that can be connected to components.
    /// </summary>
    public enum PortType
    {
        VIDEO, //Outlets connected to the monitor in order to display graphics
        POWER, //Outlets that charge the computer with electricity
        USB, //Outlets allowing the user to attach appliances and access the computer and its data
        PIN,
        OTHER
    }
}
