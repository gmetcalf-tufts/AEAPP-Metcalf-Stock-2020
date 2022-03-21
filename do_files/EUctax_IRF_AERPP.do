*********************************************
*  EUctax_IRF_AERPP.do           JS 1/8/20
*     IRFS and dynamic causal effects of carbon tax on gdp growth
*     Results for Metcalf-Stock AER P&P (2020)
*      Builds on e1123_mid19_2.do and Table6.do
*
/* ------- Variables ------------
Icountry         str32   %32s                  country
ID              str8    %9s                   LOCATION
year            int     %10.0g                Year
share19         float   %9.0g                 share GHG emissions covered by tax in 2019
dlrgdp          float   %9.0g                 Real GDP annual growth rate (percent)
dlemptot        float   %9.0g                 Total employment annual growth rate (percent)
ctaxever        float   %9.0g                 carbon tax in any year
rater_LCU_USD18 float   %9.0g                 Carbon tax rate (real, LCU, 2018 USD @ PPP)
ctaxyear        float   %9.0g                 First year of carbon tax (else missing)
EU              float   %9.0g                 member of EU ETS
EU2             float   %9.0g                 EU plus Iceland, Norway, Switzerland
*********************************************/
*read in data
use data/ctax_gdp_AERPP2018, clear
desc
*
************************************************************
* Create variables
************************************************************
*
global fxlsout "results/AERPP_Tables.xlsx"
gen rater_LCU_USD18sw = rater_LCU_USD18*share19
 label var rater_LCU_USD18sw "Carbon tax rate (real, 2018 USD) wtd by coverage share"
*
egen x99 = max(rater_LCU_USD18), by(ID)
gen CT20 = (x99>=20)
drop x99
*
* Table 1
preserve
 keep if (year==2018)*ctaxever
 sort ctaxyear ID
 keep country ctaxyear rater_LCU_USD18 share19 
 order country ctaxyear rater_LCU_USD18 share19
 label variable ctaxyear "Year"
 label variable country "Country"
 label variable rater_LCU_USD18 "Rate in 2018 (USD)"
 label variable share19 "Coverage (2019)"
 export excel $fxlsout, replace firstrow(varlabels) sheet("Table 1")  keepcellfmt
restore

************************************************************
* lag parameters and globals
************************************************************
global p = 6  // number of horizons, also number of lags in DL specifications
global lplags = 2  // number of lags in LP and XTVAR specifications

global YE "i.year"


************************************************************
*
* housekeeping
local p $p
local lplags $lplags
local pm2 = `p'-2
local pm1 = `p'-1
local pp1 = `p'+1
local lplagsm1 = `lplags'-1

************************************************************
* IRFs
*    Frameworks: DL, LP, panel VAR (as check on LP)
*    X vbles: real rate equal-wtd (rrate) and share19-wtd (rratesw)
*    Various controls
************************************************************
local controls "YE"
global controls "`controls'"
sca irfno = 0
foreach y in "lrgdp" "lemptot" {

 foreach smple in "EU2" "CT20" {
  preserve
  keep if `smple'

  if "`smple'"=="EU2" {
   local x "rater_LCU_USD18sw"
  }
  else {
   local x "rater_LCU_USD18"
  }
  *
  * set panel
  cap drop cdum
  cap drop cnum
  egen cnum = group(ID)
  xtset cnum year
  tab year, gen(ydum)
  tab ID, gen(cdum)
  local nc = r(r)
  
  * carbon tax path
  sca rateinit = 40
  if strmatch("`x'","lctaxratio*") sca rateinit = ln(1 + .40/3) // $40/ton = $0.40/gal @ $3/gal diesel
  sca swfac = 1
   if strmatch("`x'","*sw") sca swfac = 0.3
  mat xpath = J(`pp1',1,rateinit) // real carbon tax path

  global y "`y'"
  global x "`x'"
  global smple "`smple'"

 *-------------------------------------------------------------------------------------------
 *             DL estimation 
 * effect on GDP growth h-periods hence of unit step-up in x, allowing for LR effect of level of tax on GDP growth
 *-------------------------------------------------------------------------------------------
 *
   global est "DL"
   sca irfno = irfno+1
    xtreg d`y' L(0/`pm1').D.`x' L`p'.`x' $`controls', fe vce(cluster cnum)
     mat b99 = e(b)'
     mat v99 = e(V)

    do "`root'/do_files/EUctax_IRF_AERPP_out_r1.do"
 *
 *-------------------------------------------------------------------------------------------
 *             LP estimation II
 *  Via individual regs with dummy variables 
 *  Notes on SE computation:
 *    1. HAC SEs not needed, these are HR (Montiel Olea- Plagborg Moller (2019))
 *    2. SEs computed for full covariance matrix of IRFs across regressions using
 *       x's*resids for different horizon regressions. The messiness below is because
 *       the different horizon regressions are computed over different samples, so VCV matrix
 *       must be computed for the overlapping data in each covariance matrix pair.
 *    3. It is easiest coding to use SUREG to estimate all equestions at once, unfortunately
 *       sureg estimates them all on the same sample which is the sample for longest-horizon
 *       thus it is inefficient relative to OLS one-at-a-time. For sureg implementation see
 *       EUctax_IRF_2.do ("LP estimation III")
 *-------------------------------------------------------------------------------------------
 *
   global est "LP"
   mat theta11 = J(`pp1',1,1)
   sca irfno = irfno+1
    mat b99 = J(`pp1',1,0)
    mat s99 = b99
    cap drop e99*
    forvalues h = 0/`p' {
     local hp1 = `h'+1
     * effect on GDP growth h-periods hence of unit innovation in x, allowing for LR effect of level of tax on GDP growth
      reg F`h'.d`y' L(0/`lplags').`x' L(1/`lplags').d`y' $`controls' cdum*, r
     mat b98 = e(b)
     mat b99[`hp1',1] = b98[1,1]
     * create product of X projected off of controls * resids for computing HR VCV matrix
     local k = e(df_m)
     cap drop smpl`h' e`h' etax`h' zz`h'
	 qui gen smpl`h' = e(sample)
	 qui predict e`h', resid
     qui reg `x' L(1/`lplags').`x' L(1/`lplags').d`y' $`controls' cdum* if smpl`h', r
	 qui predict etax`h', resid
	 qui su etax`h' if smpl`h'
     gen zz`h' = (r(N)/(r(N)-1))*(e`h'*etax`h'/r(Var))/sqrt(r(N)-`k') if smpl`h'
     * IRF from rate shock to rate - for inverting rate path to shocks
     if `h'>0 {
      qui areg F`h'.`x' L(0/`lplags').`x' L(1/`lplags').d`y' $`controls', absorb(cnum) vce(r)
      mat b97 = e(b)
      mat theta11[`h'+1,1] = b97[1,1]
     }
    } // end of loop over horizon
	* Compute covariance matrix over different subsamples for different horizon LP estimation
	mat v99 = I(`p'+1)
	forvalues i = 0/`p' {
	 qui su zz`i'
	 mat v99[`i'+1,`i'+1] = r(Var)
	 dis `i' "   " b99[`i'+1,1] "   " sqrt(v99[`i'+1,`i'+1])
	 local ip1 = `i'+1
	 forvalues j = `ip1'/`p' {
	  qui corr zz`i' zz`j', cov
	  mat v99[`i'+1,`j'+1] = r(cov_12)
	  mat v99[`j'+1,`i'+1] = r(cov_12)
	 }
    }
	
    do "`root'/do_files/EUctax_IRF_AERPP_out_r1.do"
*
 restore
 } // smple loop
} // y loop
log close
