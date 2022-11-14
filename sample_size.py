
def min_sample_calc(confidence_level, margin_of_error, pop_size, pop_prop):
    z_map = {
        0.70: 1.04,
        0.75: 1.15,
        0.80: 1.28,
        0.85: 1.44,
        0.92: 1.75,
        0.95: 1.96,
        0.96: 2.05,
        0.98: 2.33,
        0.99: 2.58,
        0.999: 3.29,
        0.9999: 3.89,
        0.99999: 4.42
    }

    z_score = z_map[confidence_level]

    unlimited_pop = z_score * z_score * pop_prop * (1 - pop_prop) / (margin_of_error * margin_of_error)

    limited_pop = unlimited_pop/(
        1 + (z_score * z_score * pop_prop * (1 - pop_prop)) / (margin_of_error * margin_of_error * pop_size)
    )

    print(limited_pop.__ceil__())
    return limited_pop.__ceil__()


min_sample_calc(
    confidence_level=0.95,
    margin_of_error=0.005,
    pop_size=20000,
    pop_prop=0.02
)

