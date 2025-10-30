namespace KAZABUILD.Domain.Enums
{
    /// <summary>
    /// Represents different types of ports that can be connected to components.
    /// </summary>
    public enum PortType
    {
        OTHER,
        /// <summary>
        /// Outlets connected to the monitor in order to display graphics.
        /// </summary>
        VIDEO,
        /// <summary>
        /// Outlets that charge the computer with electricity.
        /// </summary>
        POWER,
        /// <summary>
        /// Outlets allowing the user to attach appliances and access the computer and its data.
        /// </summary>
        USB,
        /// <summary>
        /// Motherboard and Case pins for connecting devices.
        /// </summary>
        PIN
    }
}
