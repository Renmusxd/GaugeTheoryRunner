use std::fmt::{Display, Formatter};
use num_complex::Complex;
use serde::{Deserialize, Serialize};

#[derive(Clone, Default, Debug, Serialize, Deserialize)]
pub enum Potential {
    #[default]
    Villain,
    Cosine,
    Binary,
    Power(f32),
}

impl std::str::FromStr for Potential {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "villain" => Ok(Potential::Villain),
            "cosine" => Ok(Potential::Cosine),
            "binary" => Ok(Potential::Binary),
            ss if ss.starts_with("power(") && ss.ends_with(')') => {
                let arg = &ss[6..ss.len() - 1];
                if let Ok(arg) = f32::from_str(arg) {
                    Ok(Potential::Power(arg))
                } else {
                    Err(format!("Could not parse power float {}", arg))
                }
            }
            _ => Err(format!("Potential {} not recognized", s)),
        }
    }
}

impl From<Potential> for u8 {
    fn from(value: Potential) -> Self {
        match value {
            Potential::Villain => 0,
            Potential::Cosine => 1,
            Potential::Binary => 2,
            Potential::Power(_) => 3,
        }
    }
}

impl Potential {
    pub fn eval(&self, n: u32, k: f32) -> f32 {
        match self {
            Potential::Villain => (1.0 / k) * n.pow(2) as f32,
            Potential::Cosine => {
                if n == 0 {
                    0.0
                } else {
                    let t = complex_bessel_rs::bessel_i::bessel_i(n as f64, Complex::from(k as f64)).unwrap();
                    let b = complex_bessel_rs::bessel_i::bessel_i(0., Complex::from(k as f64)).unwrap();
                    assert!(t.im < f64::EPSILON);
                    assert!(b.im < f64::EPSILON);
                    let res = -(t.re / b.re).ln();
                    res as f32
                }
            }
            Potential::Binary => match n {
                0 => 0.0,
                1 => 1. / k,
                _ => 1000.,
            },
            Potential::Power(gamma) => (1. / k) * (n as f32).abs().powf(*gamma),
        }
    }
}

impl Display for Potential {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!("{:?}", self))
    }
}