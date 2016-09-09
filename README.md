# Overview

IMGT segment library converted to RepSeq.IO JSON format.

Git repo contains only import scripts. Results of scripts execution are available on the [release page](https://github.com/repseqio/library-imgt/releases).

# Compilation

## Requiraments

- [pup](https://github.com/ericchiang/pup)
- [repseqio](https://github.com/repseqio/repseqio)
- [jq](https://stedolan.github.io/jq/)
- wget

## Execution

To compile (import) IMGT&reg; library just execute the build script:

```
./build.sh full
```

compilation will take some time. After process is finished, you will find resulting library under the name like `imgt.v1.0.201631-4.json.gz`. Where `v1.0` stands for import script version, and `201631-4` for current IMGT reference library version.

# License

Data in this repository is imported from IMGT and is subject to terms of use listed on http://www.imgt.org site.

Data coming from IMGT server may be used for academic research only, provided that it is referred to IMGT&reg;, and cited as "IMGT&reg;, the international ImMunoGeneTics information system&reg; http://www.imgt.org (founder and director: Marie-Paule Lefranc, Montpellier, France)."

References to cite: Lefranc, M.-P. et al., Nucleic Acids Research, 27, 209-212 (1999) Cover of NAR; Ruiz, M. et al., Nucleic Acids Research, 28, 219-221 (2000); Lefranc, M.-P., Nucleic Acids Research, 29, 207-209 (2001); Lefranc, M.-P., Nucleic Acids Res., 31, 307-310 (2003); Lefranc, M.-P. et al., In Silico Biol., 5, 0006 (2004) [Epub], 5, 45-60 (2005); Lefranc, M.-P. et al., Nucleic Acids Res., 33, D593-D597 (2005) Full text, Lefranc, M.-P. et al., Nucleic Acids Research 2009 37(Database issue): D1006-D1012; doi:10.1093/nar/gkn838 Full text.

Import scripts are available under the terms of the MIT License.

THE SOFTWARE AND DATA IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
