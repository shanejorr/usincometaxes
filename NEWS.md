# usincometaxes 0.7.2

Update `taxsim.wasm` and `taxsim.js` to latest files from taxsim.app. ETag of current version is `fb937-63851e4a83800`.

The new WASM version includes 10 additional output columns:
- State columns: `srebate`, `senergy`, `sctc`, `sptcr`, `samt`
- Federal columns: `qbid`, `niit`, `addmed`, `cares`, `actc`

Documentation improvements:
- Updated output column documentation in `taxsim-output.Rmd` for new WASM version (51 total columns, up from 46)
- Added missing input column `mortgage` to `taxsim-input.Rmd` documentation
- Fixed typo: `ggsi` → `gssi` (Gross Social Security Income) in input documentation
- Added legacy dependent fields (`dep13`, `dep17`, `dep18`) to input documentation

Internal improvements:
- Added debug output filtering for new WASM version
- Added internal SSH testing infrastructure for development purposes

# usincometaxes 0.7.1

Make 2023 the most recent year you can use. TAXSIM currently does not work for 2024.

# usincometaxes 0.7.0

Update `taxsim.wasm` and `taxsim.js` to latest files. ETag of current version is `e23da-601f65ac97a40`.

Add the following old dependent columns back to input columns: 'dep13', 'dep17', 'dep18'

Add the following new columns to the output: 'credits' and 'staxbc'

# usincometaxes 0.6.0

Removed the `interface` option to `taxsim_calculate_taxes()`. Now, 'wasm' is the only interface option. Users are not able to send the data to the TAXSIM server via ssh or http. This feature was removed because we have seen unexpected changes to the TAXSIM server's output, which could silently introduce errors.

# usincometaxes 0.5.4

### Patch

- Convert errors to messages when TAXSIM cannot be connected to, as per CRAN policy 'Packages which use Internet resources should fail gracefully'.
- No longer run tests on CRAN that rely on calling the API, as per the guidance in [HTTP Testing in R](https://books.ropensci.org/http-testing/graceful.html).

# usincometaxes 0.5.3

### Patch

- TAXSIM changed its output for ssh and http and returns additional columns. Incorporate these changes,
but still only return the columns that were present before the change. Only return the original columns
so that ssh and http output aligns with wasm output.

# usincometaxes 0.5.2

### Patch

- TAXSIM added back the `tficar` column to http (see 0.5.1 for more information). Added the `tficar` column back to tests. 

# usincometaxes 0.5.1

### Patch

- TAXSIM changed how it returns http results from its server. It now adds a trailing comma at the end of each line. This causes the import functions to think there is an additional column. To solve, update http import functions to remove trailing commas.
- http results from TAXSIM no longer include the column `tficar`. This caused tests to fail. Updated tests that match http and ssh results to account for this difference.

# usincometaxes 0.5.0

### Major Changes

- Add `interface` parameter to `taxsim_calculate_taxes()`, which allows users to select the method of interfacing with TAXSIM.
- Add 'wasm' option to `interface` parameter. The functionality incorporates Aman Gupta Karmani's  [JS / WebAssembly tooling](https://github.com/tmm1/taxsim.js) into the package.  Therefore, tax calculations can be conducted locally without send and retrieving data from the TAXSIM servers. (@thomascwells, [PR #11](https://github.com/shanejorr/usincometaxes/pull/11))
- Add 'http' option to `interface` parameter. This option uses curl to send and retrieve data from TAXSIM via https. (@thomascwells, [PR #9](https://github.com/shanejorr/usincometaxes/pull/9))

# usincometaxes 0.4.0

### Minor Changes

- For ssh, create known_hosts file in temporary directory instead of .ssh.known_hosts. This is needed so that the package does not write to files outside the tempdir, in violation of CRAN requirements.
- For ssh, only use port 22.

# usincometaxes 0.3.0

### Minor Changes

Updated the input column names so that all input columns in TAXSIM are represented. 
Changed spelling on one input column name to match TAXSIM (changed 'ui' to 'sui'). ([#7](https://github.com/shanejorr/usincometaxes/pull/7), @thomascwells)

# usincometaxes 0.2.0

### Major Changes

- Updated to TAXSIM 35. Data is now sent to the TAXSIM 35 server instead of the TAXSIM 32 server.
- Changed column names of input columns so that they now match TAXSIM 35's input column names.
