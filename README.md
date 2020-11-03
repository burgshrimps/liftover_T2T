# LiftOver hg38 to T2T

Recently the Telomere-to-Telomere consoritum published a complete [T2T reconstruction of a human genome](https://github.com/nanopore-wgs-consortium/CHM13) with the exception of 5 gaps. In order to jump between hg38 and the T2T assembly one can use the tool [liftOver](https://genome.ucsc.edu/cgi-bin/hgLiftOver). LiftOver requires a so-called chain files to convert a set of coordinates from one assembly to the other.
