# LiftOver hg38 to T2T

Recently the Telomere-to-Telomere consoritum published a complete [T2T reconstruction of a human genome](https://github.com/nanopore-wgs-consortium/CHM13) with the exception of 5 gaps. In order to jump between hg38 and the T2T assembly one can use the tool [liftOver](https://genome.ucsc.edu/cgi-bin/hgLiftOver). LiftOver requires a so-called chain file to convert a set of coordinates from one assembly to the other. In this repository you can find such chain files, the Shell scripts which were used to produce it as well as a simple Python script to convert a single coordinate on the fly!

## Prerequisites
For coordinate conversions using an exisiting chain file, such as the one provided in this repository, only [pyliftover](https://pypi.org/project/pyliftover/) is needed. If one wants to create their own chain file using the providid scripts the following tools need to be installed:
* faToTwoBit
* faSplit
* twoBitInfo
* blat
* liftUp
* axtChain
* chainMergeSort
* chainNet
* netChainSubset

## Coordinate Conversion

'''
python3 
'''
