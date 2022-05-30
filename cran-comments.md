## R CMD check results

0 errors | 0 warnings | 2 notes

Notes: 

* Possibly misspelled words in DESCRIPTION:
    * NBER's (7:12)
    * TAXSIM (7:19, 7:81, 8:65, 9:5)
    
These words are not misspelled. They are acronyms.

* Resubmission from a package archived due to violating CRAN's policies. The policy violation message is below:

> Apparently checking this modifies the user's ~/.ssh/known_hosts, in violation of the CRAN Policy's
>
>   Packages should not write in the user’s home filespace (including
>   clipboards), nor anywhere else on the file system apart from the R
>   session’s temporary directory ...
>
>We thus have to archive your package for policy violation.

Package was fixed so that a known_hosts file is created in the tempdir and this file is subsequently modified.

## Downstream dependencies

There are no downstream dependencies.
