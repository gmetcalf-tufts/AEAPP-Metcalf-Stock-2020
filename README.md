# AEAPP-Metcalf-Stock-2020 
## [Measuring the Macroeconomic Impact of Carbon Taxes](https://www.aeaweb.org/articles?id=10.1257/pandp.20201081)
Data and code for: Metcalf, Gilbert E., and James H. Stock. 2020. "Measuring the Macroeconomic Impact of Carbon Taxes." AEA Papers and Proceedings, 110: 101-06.
### Overview
The code in this replication package constructs the tables and figures using Stata. The master file runs all of the code to generate two tables and two appendix figures.
### Description of files and code:
- `master_MetcalfStock.do` will run all the files to construct the final tables and figures.
- `do_files` contains the do files run by the master file.
  - **Creating the dataset**: `names.do`, `employment.do`, `GDP.do`, `ctax.do`, and `merge and calculate.do` create the dataset for analysis.
  - **Analysis**: `EUctax_IRF_AERPP.do` runs the analysis and creates the paper tables.
  - **Appendix figures**: `EUctax_IRF_5.do`, `EUctax_IRF_AERPP_out_r1.do`, and `EUctax_IRF_CIRF_lun_tabfig.do` create the appendix figures.
-  `stata` contains the raw data, the dataset used for analysis, and the results.
-  `Replication memo.docx` details the sources for all raw data.
### Instructions to Replicators
Edit `master_MetcalfStock.do` to change the default path.
### Note
In March 2020 we found a data bug that makes minor changes to some EU2 results. So, the EU2 results in the out\AERPP_results.xlsx spreadsheet don't match Table 2 exactly for EU2, although they do match for the CT20 countries (countries with CT >= $20). There are no qualitative changes. For example, the upper left estimate in Table 2 is 0.10 (SE = 0.43). Using the corrected data, the result is (0.14) (SE = 0.41). 
Another bug causes small rounding discrepancies from the results in Table 2.
