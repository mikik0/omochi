This library has 5 major steps.

1. Fetch Ruby files from diffs, including spec files
2. Parse them to AST
3. Get all methods and spec `describe`s and compare
4. If every method is covered, successfully return, otherwise print their names
5. If `--create` option is given, generate skeletons for missing specs
