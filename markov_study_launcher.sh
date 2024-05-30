#!/bin/bash

 qsub -P qscmp -t 1:304 -l h_rt=0:01:00 GaugeTheoryRunner/markov_scc.sh markov_winding/villain 4 8192 villain 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py
 qsub -P qscmp -t 1:304 -l h_rt=0:01:00 GaugeTheoryRunner/markov_scc.sh markov_winding/binary 4 8192 binary 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py

 qsub -P qscmp -t 1:304 -l h_rt=0:04:00 GaugeTheoryRunner/markov_scc.sh markov_winding/villain 6 8192 villain 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py
 qsub -P qscmp -t 1:304 -l h_rt=0:04:00 GaugeTheoryRunner/markov_scc.sh markov_winding/binary 6 8192 binary 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py

 qsub -P qscmp -t 1:304 -l h_rt=0:16:00 GaugeTheoryRunner/markov_scc.sh markov_winding/villain 8 8192 villain 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py
 qsub -P qscmp -t 1:304 -l h_rt=0:16:00 GaugeTheoryRunner/markov_scc.sh markov_winding/binary 8 8192 binary 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py

 qsub -P qscmp -t 1:304 -l h_rt=1:00:00 GaugeTheoryRunner/markov_scc.sh markov_winding/villain 10 8192 villain 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py
 qsub -P qscmp -t 1:304 -l h_rt=1:00:00 GaugeTheoryRunner/markov_scc.sh markov_winding/binary 10 8192 binary 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py

 qsub -P qscmp -t 1:304 -l h_rt=4:00:00 GaugeTheoryRunner/markov_scc.sh markov_winding/villain 12 8192 villain 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py
 qsub -P qscmp -t 1:304 -l h_rt=4:00:00 GaugeTheoryRunner/markov_scc.sh markov_winding/binary 12 8192 binary 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py

 qsub -P qscmp -t 1:304 -l h_rt=16:00:00 GaugeTheoryRunner/markov_scc.sh markov_winding/villain 14 8192 villain 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py
 qsub -P qscmp -t 1:304 -l h_rt=16:00:00 GaugeTheoryRunner/markov_scc.sh markov_winding/binary 14 8192 binary 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py

 qsub -P qscmp -t 1:304 -l h_rt=24:00:00 GaugeTheoryRunner/markov_scc.sh markov_winding/villain 16 8192 villain 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py
 qsub -P qscmp -t 1:304 -l h_rt=24:00:00 GaugeTheoryRunner/markov_scc.sh markov_winding/binary 16 8192 binary 8 GaugeTheoryRunner/target/release/markov GaugeTheoryRunner/markov_study_winding.py