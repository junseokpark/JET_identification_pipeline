[![ubuntu](https://img.shields.io/badge/ubuntu-18.04_LTS-E95420?style=flat&logo=ubuntu)](https://releases.ubuntu.com/18.04/)
[![R](https://img.shields.io/badge/R-v3.6.3-3776AB?style=flat&logo=R&logoColor=276DC3)](https://cran.r-project.org/bin/windows/base/old/3.6.3/)

# README for "JET identification pipeline" repository

-------------------------------------------------------
###    Created by Alexandre Houy and Christel Goudot
###    Modified and adapted by Ares Rocanin-Arjo
###    				07/2022
###    Modified by Junseok Park, 11/2024
###    Major updates to enable fusion calling using Human hg38 (Step3 was excluded for the modification)
-------------------------------------------------------

This pipeline was used in the manuscript: Epigenetically-controlled tumor antigens derived from splice junctions between exons and transposable elements (Burbage, M. and Rocanin-Arjo, A.) to identify, quantify and select non-canonical splice junctions between exons and transposable elements (or JETs).
It consists in 3 bash (.sh) scripts and one Rscript.  
	1- Step1_pipelineJETs_STAR.sh  
	2- Step2_pipelineJETs_R.sh  
	3- JET_analysis_filtered.R  
	4- Step3_pipelineJETs_netMHCpan.sh  

The R script, is called by one of the sh files(the Step2). 
In all three of them there are paths and files that must be defined to adapt the script to your computer environment and references files. This are indicated as `_introducePATH_` or `_introduce PATH/filename_` (also `_PATH/filename_gtf_` or `_PATH/filename_FASTA_`) in the scipts.


This particular script requires the following softwares and versions:
- STAR 2.5.3
- samtools-1.3
- Rproject software 3.2.3 with packages biovizBase1.18.0, GenomicAligments1.6.3, GenomicFeatures_1.22.13, data.table_1.12.8, scales_1.1.0, ggplot2_3.2.1.

It will also require a repeat masker annotation file from USCS. The indication are:
#### INDICATIONS TO DOWNLOAD ANNOTATION: 
Files downloaded from UCSC table --- done once  

- Go to : Tools - Table browser  
    * clade               : Mammal  
    * genome              : <organism>  
    * assembly            : <genome>  
    * group               : Variation and Repeats  
    * track               : RepeatMasker  
    * table               : rmsk  
    * region              : genome  
    * output format       : select fields from primary and related table  
    * output file         : <genome>.repeatmasker_reformat.txt  
    * file type returned : plain text  
  -> Click get output  
	
 - Select  
		* genoName  
		* genostart  
		* genoend  
		* strand  
		* repName  
		* repClass  
		* repfamily  
 -> Click get output  

Also the path and filename must be indicated in the R script in the 118th line.  
  
### Citation
Please use the following information to cite:

### Contact the Author
Ares Rocanin-Arjo: maria-ares.rocanin-arjo@curie.fr, Marianne Burbage: marianne.burbage@curie.fr and Christel Goudot: christel.goudot@curie.fr

### Contact the modifier 
[Junseok Park](mailto:junseok.park@childrens.harvard.edu)

# Licenses
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![License: CC BY-NC 4.0](https://img.shields.io/badge/License-CC_BY--NC_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc/4.0/)
[![License: GPL v2](https://img.shields.io/badge/License-GPL_v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)