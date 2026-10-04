# V1.5 UNIT HYDROGRAPH

Implements SCS Dimensionless Unit Hydrograph transform method:
$$q_p = \frac{0.208 \cdot A}{T_p}, \quad T_p = \frac{\Delta t}{2} + T_l$$
Convolves dimensionless ordinates against rainfall excess series to produce direct runoff hydrographs.
