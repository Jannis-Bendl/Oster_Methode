
	* REPLICATORS: change machine to project directory 
	* - (replace NETID with own NetID)
	global machine		"/gpfs/kellogg/proj/NETID"
	global proj			"${machine}/Schnell2026_Replication"
	
	* Publicly available data
	global raw_public	"${proj}/rawdata"
	
	* Restricted-access data (do not modify these paths)
	global restricted	"/gpfs/kellogg/proj/mks401"
	global raw_IMS	 	"${restricted}/iqvia/_ims"	
	global raw_LRx	 	"${restricted}/iqvia/_raw_data"	
	global raw_NVSS		"${restricted}/DATA/NVSS/raw/txt"
	global raw_SRx		"${restricted}/Opioids_JMP/1_data/StreetRx/raw"
	
	* Directory structure
	global code			"${proj}/code"
	global inter		"${proj}/intermediate"
	global results		"${proj}/results"
	
	* Set default graphic options
	graph set eps fontface Times
	graph set eps logo off
	set scheme s2color, perm

	* Install required user-written packages
	local pkgs "spmap geo2xy geoinpoly shp2dta kdens regsave psacalc sxpose texsave statastates egenmore moremata"
	foreach p of local pkgs {
		cap which `p'
		if _rc {
			di as txt "Installing required Stata package: `p'"
			cap quietly ssc install `p', replace
			if _rc {
				di as error "ERROR: Could not install `p' from SSC. Please install manually and re-run."
				exit 198
			}
		}
	}
