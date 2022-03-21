*********************************************
* Modified by Siddhi D. 2/20/22
*  EUctax_IRF_5.do           JS 10/14/19, 11/22-24/19, 12/19/19-1/2/20, 3/11/20, 3/30/20, 5/25/20, 6/11-20/20
*     IRFS and dynamic causal effects of carbon tax on gdp growth
*      Data set created by modularized programs, combined with "merge and calculate.do"
*      
*
/* ------- Variables ------------
country         str32   %32s                  country
ID              str8    %9s                   
year            int     %10.0g                year
rate_CTI_USD    double  %14.2f                carbon tax rate from WB CTI (nominal USD)
share           double  %10.0g                share of jurisdiction's GHG emissions covered by tax
share19         float   %9.0g                 share of jurisdiction's GHG emissions covered by tax in 2019
ctax            float   %9.0g                 
ctaxever        float   %9.0g                 carbon tax in any year
rrate           float   %9.0g                 Carbon tax rate (2016 USD)
ctaxyear        float   %9.0g                 First year of carbon tax (else missing)
EU              float   %9.0g                 member of EU ETS
EU2             float   %9.0g                 EU plus Switzerland
EU3             float   %9.0g                 EU+CHE+US+CA+JPN
*********************************************/
*
*------------------------------------------------------------------------------------------------*
* Program to compute IRF for VAR(svlags) wrt first variable shock, given estimated coefficients in b
*Syntax program var2irf svlags p    where svlags = number of VAR lags and p = number of horizons 
cap program drop varirf
program varirf
 local svlags = `1' // first argument is svlags
 local p = `2'      // second argument is VAR lag length
 local pp1 = `p'+1
 local k0 = 2*`svlags'
 mat A0 = [1, 0 \ -b[1,`k0'+1], 1]
 mat A0inv = inv(A0)
 mat BLR = A0inv
 local ki = 1
 forvalues i = 1/`svlags' {
   mat A`i' = b[1,`ki'..`ki'+1] \ b[1,`k0'+`ki'+1..`k0'+`ki'+2]
   mat B`i' = A0inv*A`i'
   mat BLR = BLR - B`i'
   local ki = `ki'+2
 }
 mat BLRinv = inv(BLR)
 sca theta21lr = BLRinv[2,1]
 mat eps1 = A0inv*[1 \ 0]
 mat vtheta1 = J(2,`svlags',0) , eps1
 forvalues j = 2/`pp1' {
  mat xj = J(2,1,0) 
   forvalues i = 1/`svlags' {
    mat xj = xj + B`i'*vtheta1[1..2,colsof(vtheta1)-`i'+1]
   }
   mat vtheta1 = vtheta1, xj
 }
 mat theta1_var = vtheta1[1..2,`svlags'+1..colsof(vtheta1)]'
end

*read in data
use data/ctax_gdp_AERPP2018, clear
desc

************************************************************
* Create variables
************************************************************
gen ctaxno = (ctaxyear==.)
gen ctaxpre = (year<ctaxyear)*(1-ctaxno)
*
gen rater_LCU_USD18sw = rater_LCU_USD18*share19
 label var rater_LCU_USD18sw "Carbon tax rate (real, 2018 USD) wtd by coverage share"

keep if tin(1985,2018)
*
replace rater_LCU_USD18sw = 0 if rater_LCU_USD18sw==.
save ctax_gdp_tmp, replace
*
* modify the dsetno list to run different subsamples of the data (dfferent country groups)
forvalues dsetno = 1/1 {
************************************************************
* Select data subset
************************************************************
use ctax_gdp_tmp, clear
*
* ----- EU+ sample --------
keep if EU2
drop if ID=="LIE"
global smple "EU+"

************************************************************
* set panel
************************************************************
cap drop cnum
cap drop cdum
egen cnum = group(ID)
xtset cnum year
local smple "$smple"
tab year, gen(ydum)
tab ID, gen(cdum)
local nc = r(r)
*
************************************************************
* IRFs
*    Frameworks: DL, LP, panel VAR 
*    X vbles: real rate equal-wtd (rrate) and share19-wtd (rratesw)\
*		rater_LCU_USD18sw = World bank carbon tax rate weighted by coverage share-weighted
*		ecp2018sw = Dolphin et al share-weighted carbon tax rate
*    Various controls
*    y variables:
*		lrgdp = log real GDP
*		lemptot = log total employment

************************************************************

* ----- Set main run parameters ----------------
global p = 8       // number of horizons (years), also number of lags in DL specifications
global pplot = 6   // number of horizons for IRF plot
global lplags = 4  // number of lags in LP specifications, also number of lags of controls in all specifications (0,...,lplags-1)
global svlags = 4  // number of lags in SVAR specifications
global speclist "L" // L = x enters in levels: effect on GDP growth h-periods hence of unit step-up in x, allowing for LR effect of level of tax on GDP growth 

global controls "YE"      // set list of sets of control variables
global yvars "lrgdp" "lemptot" //dependent variable list for y loop. NOTE: needs to be string list not varlist
global xvars "rater_LCU_USD18sw"

*
local p $p
global dllags `p'
local lplags $lplags
local svlags $svlags
local lplagsm1 = `lplags'-1
local pm2 = `p'-2
local pm1 = `p'-1
local pp1 = `p'+1
global none ""
global YE "i.year"

foreach spec in "$speclist" {
 global spec "`spec'"
 if "`spec'" == "L" {
  local DS = ""
  mat xpath0 = J(`pp1',1,1) // real carbon tax path
 }
 else {
  local DS = "D."
  mat xpath0 = 1 \ J(`p',1,0) // real carbon tax path
 }
*
foreach y in "$yvars"  {
 global y "`y'"
 cap erase "out\irfs_`y'_`smple'_`spec'_4.xlsx"
 *
 foreach x in "$xvars" {
  sca irfno = 0
  sca rateinit = 40
  if strmatch("`x'","lctaxratio*") sca rateinit = ln(1 + .40/3) // $40/ton = $0.40/gal @ $3/gal diesel
  if strmatch("`x'","receiptsr_LCU_USD18_pc") sca rateinit = 0.40*142000/327 // $40/ton = $0.40/gal @ 142000/327 gallons per person per year = $173/year
  sca swfac = 1
   if strmatch("`x'","*sw") sca swfac = 0.3
  mat xpath = rateinit*xpath0
  sca dirfno = 1
  global x "`x'"
  global xsheet "`x'"

 *-------------------------------------------------------------------------------------------
 *             LP estimation 
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
   sca fgc = .
   sca pgc = .
   foreach controls in $controls {
    sca irfno = irfno+dirfno
    mat theta21 = J(`pp1',1,0)
    cap drop e99*
    forvalues h = 0/`p' {
     local hp1 = `h'+1
      reg F`h'.d`y' L(0/`lplags').`DS'`x' L(1/`lplags').d`y' $`controls' cdum*, r
     mat b98 = e(b)
     mat theta21[`hp1',1] = b98[1,1]
     * product of X projected off of controls * resids for VCV matrix
     local k = e(df_m)
     cap drop smpl`h' e`h' etax`h' zz`h'
	 qui gen smpl`h' = e(sample)
	 qui predict e`h', resid
     *qui reg `x' L(1/`lplags').`x' L(1/`lplags').d`y' $`controls' cdum* if smpl`h', r
     qui reg `DS'`x' L(1/`lplags').`DS'`x' L(1/`lplags').d`y' $`controls' cdum* if smpl`h', r
	 qui predict etax`h', resid
	 qui su etax`h' if smpl`h'
     gen zz`h' = (r(N)/(r(N)-1))*(e`h'*etax`h'/r(Var))/sqrt(r(N)-`k') if smpl`h'
*    IRF from rate shock to rate - for inverting rate path to shocks
*    Results are very insensitive to whether eqn is restricted to obs only once tax is initiated
     if `h'>0 {
      qui areg F`h'.`DS'`x' L(0/`lplags').`DS'`x' L(1/`lplags').d`y' $`controls', absorb(cnum) vce(r)
      mat b97 = e(b)
      mat theta11[`h'+1,1] = b97[1,1]
     }
    } // end of loop over horizon
*   Compute covariance matrix over different subsamples for different horizon LP estimation
	mat vtheta21 = I(`p'+1)
	forvalues i = 0/`p' {
	 qui su zz`i'
	 mat vtheta21[`i'+1,`i'+1] = r(Var)
	 dis `i' "   " theta21[`i'+1,1] "   " sqrt(vtheta21[`i'+1,`i'+1])
	 local ip1 = `i'+1
	 forvalues j = `ip1'/`p' {
	  qui corr zz`i' zz`j', cov
	  mat vtheta21[`i'+1,`j'+1] = r(cov_12)
	  mat vtheta21[`j'+1,`i'+1] = r(cov_12)
	 }
    }
	global controls `controls'
	global nlags "`lplags'"
    do "`root'/do_files/EUctax_IRF_CIRF_lin_tabfig"
  }

*-------------------------------------------------------------------------------------------
 } //Loop y
} //Loop x
} //Loop spec
} // Loop dsetno
erase ctax_gdp_tmp.dta

