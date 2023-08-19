This folder contains older versions of the taxsim.wasm and taxsim.js files. The 
folder names represent that last version that the files were used with.

We can check the current version on the TAXSIM servers with:

```
curl --head -v -o /dev/null http://taxsim.nber.org/taxsim35/taxsim.wasm 2>&1 | grep ETag
```

The most recent version in `usincometaxes` will be in the change log.
