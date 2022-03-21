* EUctax_IRF_AERPP_out_r1.do   JS 1/8/20 SD 02/19/22
*   called from EUctax_IRF_AERPP.do
*   Writes excel spreadsheet of IRFs and SEs
*   Input are coefficient-level IRFs, VCV matrix, and (for LP) X-variable IRFs for innovation
*   Outputs are IRFs for $40 carbon tax
*
quietly
local y "$y"
local x "$x"
local est "$est"
local controls "$controls"
local smple "$smple"
local p $p
local pp1 = `p'+1
if irfno == 1 {
 putexcel set $fxlsout, modify sheet("Table 2")
 qui putexcel A1 = "Table 2 - Estimated Growth Impacts"
 qui putexcel A3 = "y"
 qui putexcel B3 = "Method"
 qui putexcel C3 = "Sample"
 qui putexcel D2 = "Impact in year"
 qui putexcel D3   = "0"
 qui putexcel E3   = "1-2"
 qui putexcel F3   = "3-5"
}
* --------- Compute IRF wrt scaled shock and its VCV ------------
if ("`est'" == "DL") {
 mat ratefac = swfac*xpath[1,1]
 mat irf = ratefac*b99[1..`pp1',1]
 mat virf = ratefac*ratefac*v99[1..`pp1',1..`pp1']
}
if ("`est'" == "LP") {
 * (i) compute the shocks to x that deliver the desired x path 
 mat B = I(`p'+1)
 forvalues h = 1/`p' {
  forvalues i = 1/`h' {
   mat B[`h'+1,`i'] = theta11[`h'-`i'+2,1]'
  }
 }
 mat epsx = inv(B)*xpath*swfac
 * (ii) compute IRF and its covariance matrix wrt the x shocks
 mat shockmat = I(`pp1')
 forvalues i = 1/`pp1' {
  forvalues j = `i'/`pp1' {
   mat shockmat[`i',`j'] = epsx[`j'-`i'+1,1]
  }
  /*
 * Alternative (equivalent) VIRF calculation
 mat L = J(`p'+1,`p'+1,0)
 forvalues i = 1/`p' {
  mat L[`i'+1,`i']=1
 }
 mat S = I(`p'+1) 
 mat Lp = I(`p'+1)
 forvalues i = 1/`p' {
  mat Lp = Lp*L
  mat S = S , Lp
 }
 mat list Lp
 mat list S
 mat H = vec(I(`p'+1)) * vec(I(`p'+1))'
 mat list H
 mat D = epsx' # S
 mat virf88 = D * (H # v99) * D'
 mat list virf88
 mat list virf
 */
 }
 mat irf = shockmat'*b99
 mat virf = shockmat'*v99*shockmat
 }
*
mat seirf = vecdiag(cholesky(diag(vecdiag(virf))))'
* IRF at lag 0, average of 1&2, average of 3,4,&5
mat A = [1  ,0  ,0  ,0  ,0  ,0  ,0\    ///
         0  ,0.5,0.5,0  ,0  ,0  ,0\    ///
	     0  ,0  ,0  ,1/3,1/3,1/3,0]
mat irfavg = A*irf
mat seirfavg = vecdiag(cholesky(diag(vecdiag(A*virf*A'))))'
mat list irfavg
mat list seirfavg

local rn = irfno*2+2
local rnp1 = `rn'+1
 qui putexcel A`rn'   = "`y'"
 qui putexcel B`rn'   = "`est'"
 qui putexcel C`rn'   = "`smple'"
 qui putexcel D`rn'   = matrix(irfavg'), nformat(###.00)
 qui putexcel D`rnp1' = matrix(seirfavg'), nformat(###.00)
 
noisily
