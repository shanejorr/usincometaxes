# usincometaxes 0.5.0

### Major Changes

- Add `interface` parameter to `taxsim_calculate_taxes()`, which allows users to select the methode of interfacing with TAXSIM.
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
