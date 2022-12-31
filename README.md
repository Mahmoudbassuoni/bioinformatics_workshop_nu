# Bioinformatics_Workshop_NU
A bioinformatics tutorial on alignment and variant calling. This Tutorial was copied and edited from [Erik Garrison](https://github.com/ekg/alignment-and-variant-calling-tutorial) under [licence](https://github.com/ekg/alignment-and-variant-calling-tutorial/blob/master/LICENSE). 
# NGS alignment and variant calling
## Part [1]: Docker Installation and Image start
**All tools needed was downloaded and installed on a docker image for anyone to be able to reproduce the same data without errors**
### 1.1 Download Docker
#### 1. Update the apt package index and install packages to allow apt to use a repository over HTTPS:
```
sudo apt-get update && \
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```    
#### 2.Add Docker’s official GPG key:
```
sudo mkdir -p /etc/apt/keyrings && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```
#### 3.Use the following command to set up the repository:
```
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
### 1.2 Install Docker Engine
#### 1.Update the apt package index:
```
sudo apt-get update
```
#### 2.Install Docker Engine, containerd, and Docker Compose. 
```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```
#### 3.Verify that the Docker Engine installation is successful by running the hello-world image:
```
sudo docker run hello-world
```
### 1.3 Install our tutorial docker image
```
sudo docker pull mahmoudbassyouni/bioinformatics_workshop_nu:v2
```
### 1.4 Run the docker image
```
sudo docker run -it -v $HOME:$HOME mahmoudbassyouni/bioinformatics_workshop_nu:v2
```
## Part [2]: Aligning E. Coli data with bwa mem
[E. Coli K12](https://en.wikipedia.org/wiki/Escherichia_coli#Model_organism) is a common laboratory strain that has lost its ability to live in the human intestine, but is ideal for manipulation in a controlled setting. The genome is relatively short, and so it's a good place to start learning about alignment and variant calling. 
### 2.1 E. Coli K12 reference
We'll get some test data to play with. First, [the E. Coli K12 reference](http://www.ncbi.nlm.nih.gov/nuccore/556503834), from NCBI. It's a bit of a pain to pull out of the web interface so [you can also download it here](http://hypervolu.me/~erik/genomes/E.coli_K12_MG1655.fa). First let's create our directories to organize our files and then check our referrence genome. 
```
mkdir workshop workshop/ref workshop/K12 workshop/O104 workshop/alignment workshop/variant_calling && cd workshop/ref
```
```
curl -s http://hypervolu.me/%7Eerik/genomes/E.coli_K12_MG1655.fa > E.coli_K12_MG1655.fa
```
```
# the start of the genome, which is circular but must be represented linearly in FASTA
curl -s http://hypervolu.me/%7Eerik/genomes/E.coli_K12_MG1655.fa | head
# >NC_000913.3 Escherichia coli str. K-12 substr. MG1655, complete genome
# AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC
# TTCTGAACTGGTTACCTGCCGTGAGTAAATTAAAATTTTATTGACTTAGGTCACTAAATACTTTAACCAA
# ...
```
### 2.2 E. Coli K12 Illumina 2x300bp MiSeq sequencing results
For testing alignment, let's get some data from a [recently-submitted sequencing run on a K12 strain from the University of Exeter](http://www.ncbi.nlm.nih.gov/sra/?term=SRR1770413). We can use the sratoolkit to directly pull the sequence data (in paired FASTQ format) from the archive:
```
cd ../K12 && \ 
fastq-dump --split-files ./SRR1770413
```
`fastq-dump` is in the SRA toolkit. It allows directly downloading data from a particular sequencing run ID. SRA stores data in a particular compressed format (SRA!) that isn't directly compatible with any downstream tools, so it's necessary to put things into FASTQ for further processing. The `--split-files` part of the command ensures we get two files, one for the first and second mate in each pair. We'll use them in this format when aligning.
### 2.3 E. Coli O104:H4 HiSeq 2000 2x100bp
As a point of comparison, let's also pick up a [sequencing data set from a different E. Coli strain](http://www.ncbi.nlm.nih.gov/sra/SRX095630%5Baccn%5D). This one is [famous for its role in foodborne illness](https://en.wikipedia.org/wiki/Escherichia_coli_O104%3AH4#Infection) and is of medical interest.
```
cd ../O104 && \
fastq-dump --split-files ./SRR341549
```
### 2.4 Setting up our reference indexes
#### FASTA file index
First, we'll want to allow tools (such as our variant caller) to quickly access certain regions in the reference. This is done using the samtools `.fai` FASTA index format, which records the lengths of the various sequences in the reference and their offsets from the beginning of the file.
```
cd ../ref && \
samtools faidx E.coli_K12_MG1655.fa
```
Now it's possible to quickly obtain any part of the E. Coli K12 reference sequence. For instance, we can get the 200bp from position 1000000 to 1000200. We'll use a special format to describe the target region `[chr]:[start]-[end]`.
```
samtools faidx E.coli_K12_MG1655.fa NC_000913.3:1000000-1000200
```
We get back a small FASTA-format file describing the region:
```
>NC_000913.3:1000000-1000200
GTGTCAGCTTTCGTGGTGTGCAGCTGGCGTCAGATGACAACATGCTGCCAGACAGCCTGA
AAGGGTTTGCGCCTGTGGTGCGTGGTATCGCCAAAAGCAATGCCCAGATAACGATTAAGC
AAAATGGTTACACCATTTACCAAACTTATGTATCGCCTGGTGCTTTTGAAATTAGTGATC
TCTATTCCACGTCGTCGAGCG
```
#### BWA's FM-index
BWA uses the [FM-index](https://en.wikipedia.org/wiki/FM-index), which a compressed full-text substring index based around the [Burrows-Wheeler transform](https://en.wikipedia.org/wiki/Burrows%E2%80%93Wheeler_transform). To use this index, we first need to build it:
```
bwa index E.coli_K12_MG1655.fa
```
You should see `bwa` generate some information about the build process:
```
[bwa_index] Pack FASTA... 0.04 sec
[bwa_index] Construct BWT for the packed sequence...
[bwa_index] 2.26 seconds elapse.
[bwa_index] Update BWT... 0.04 sec
[bwa_index] Pack forward-only FASTA... 0.03 sec
[bwa_index] Construct SA from BWT and Occ... 0.72 sec
[main] Version: 0.7.8-r455
[main] CMD: bwa index E.coli_K12_MG1655.fa
[main] Real time: 3.204 sec; CPU: 3.121 sec
```
And, you should notice a new index file which has been made using the FASTA file name as prefix:
```
ls -rt1 E.coli_K12_MG1655.fa*
```
```
# -->
E.coli_K12_MG1655.fa
E.coli_K12_MG1655.fa.fai
E.coli_K12_MG1655.fa.bwt
E.coli_K12_MG1655.fa.pac
E.coli_K12_MG1655.fa.ann
E.coli_K12_MG1655.fa.amb
E.coli_K12_MG1655.fa.sa
```
### 2.5 Aligning our data against the E. Coli K12 reference
Here's an outline of the steps we'll follow to align our K12 strain against the K12 reference:

1. use bwa to generate SAM records for each read
2. convert the output to BAM
3. sort the output
4. mark PCR duplicates that result from exact duplication of a template during amplification

We could the steps one-by-one, generating an intermediate file for each step. However, this isn't really necessary unless we want to debug the process, and it will make a lot of excess files which will do nothing but confuse us when we come to work with the data later. Thankfully, it's easy to use [nix pipes](https://en.wikiepdia.org/wiki/Pipeline_%28Unix%29) stream most of these tools together.See this [nice thread about piping bwa and samtools together on biostar](https://www.biostars.org/p/43677/) for a discussion of the benefits and possible drawbacks of this.

You can now run the alignment using a piped approach. Replace `$threads` with the number of CPUs you would like to use for alignment. Not all steps in `bwa` run in parallel, but the alignment, which is the most time-consuming step, does. You'll need to set this given the available resources you have. 
```
#To check your cpus you can use this command:
htop
```
```
cd ../alignment 
bwa mem -t $threads -R '@RG\tID:K12\tSM:K12' \
    ../ref/E.coli_K12_MG1655.fa ../K12/SRR1770413_1.fastq ../K12/SRR1770413_2.fastq \
    | samtools view -b - >SRR1770413.raw.bam
sambamba sort SRR1770413.raw.bam
sambamba markdup SRR1770413.raw.sorted.bam SRR1770413.bam
```
Breaking it down by line:

* alignment with bwa: `bwa mem -t $threads -R '@RG\tID:K12\tSM:K12'` --- this says "align using so many threads" and also "give the reads the read group K12 and the sample name K12"
* reference and FASTQs `E.coli_K12_MG1655.fa SRR1770413_1.fastq.gz SRR1770413_2.fastq.gz` --- this just specifies the base reference file name (`bwa` finds the indexes using this) and the input alignment files. The first file should contain the first mate, the second file the second mate.
* conversion to BAM: `samtools view -b -` --- this reads SAM from stdin (the `-` specifier in place of the file name indicates this) and converts to BAM.
* sorting the BAM file: `sambamba sort SRR1770413.raw.bam` --- sort the BAM file, writing it to `.sorted.bam`.
* marking PCR duplicates: `sambamba markdup SRR1770413.raw.sorted.bam SRR1770413.bam` --- this marks reads which appear to be redundant PCR duplicates based on their read mapping position. It [uses the same criteria for marking duplicates as picard](http://lomereiter.github.io/sambamba/docs/sambamba-markdup.html).

Now, run the same alignment process for the O104:H4 strain's data. Make sure to specify a different sample name via the `-R '@RG...` flag incantation to specify the identity of the data in the BAM file header and in the alignment records themselves:

```
bwa mem -t $threads -R '@RG\tID:O104_H4\tSM:O104_H4' \
    ../ref/E.coli_K12_MG1655.fa ../O104/SRR341549_1.fastq  ../O104/SRR341549_2.fastq \
    | samtools view -b - >SRR341549.raw.bam
sambamba sort SRR341549.raw.bam
sambamba markdup SRR341549.raw.sorted.bam SRR341549.bam
```
As a standard post-processing step, it's helpful to add a BAM index to the files. This let's us jump around in them quickly using BAM compatible tools that can read the index. sambamba does this for us by default, but if it hadn't or we had used a different process to generate the BAM files, we could use samtools to achieve exactly the same index.
```
samtools index SRR1770413.bam && samtools index SRR341549.bam
```
## Part [3]: Variant Calling 
Now that we have our alignments sorted, we can quickly determine variation against the reference by scanning through them using a variant caller. There are many options, including [samtools mpileup](http://samtools.sourceforge.net/samtools.shtml), [platypus](https://www.well.ox.ac.uk/research/research-groups/lunter-group/lunter-group/platypus-documentation), and the [GATK](https://gatk.broadinstitute.org/hc/en-us).

For this tutorial, we'll keep things simple and use [freebayes](https://github.com/freebayes/freebayes). It has a number of advantages in this context (bacterial genomes), such as long-term support for haploid (and polyploid) genomes. However, the best reason to use it is that it's very easy to set up and run, and it produces a very well-annotated VCF output that is suitable for immediate downstream filtering.

### 3.1 Joint calling with `freebayes`
We can put the samples together if we want to find differences between them. Calling them jointly can help if we have a population of samples to use to help remove calls from paralogous regions. The Bayesian model in freebayes combines the data likelihoods from sequencing data with an estimate of the probability of observing a given set of genotypes under assumptions of neutral evolution and a [panmictic](https://en.wikipedia.org/wiki/Panmixia) population. For instance, [it would be very unusual to find a locus at which all the samples are heterozygous](https://en.wikipedia.org/wiki/Hardy%E2%80%93Weinberg_principle). It also helps improve statistics about observational biases (like strand bias, read placement bias, and allele balance in heterozygotes) by bringing more data into the algorithm.

However, in this context, we only have two samples and the best reason to call them jointly is to make sure we have a genotype for each one at every locus where a non-reference allele passes the caller's thresholds in either sample.

We would run a joint call by dropping in both BAMs on the command line to freebayes:
```
cd ../variant_calling && \
freebayes -f ../ref/E.coli_K12_MG1655.fa --ploidy 1 ../K12/SRR1770413.bam ../O104/SRR341549.bam >e_colis.vcf
```
As long as we've added the read group (@RG) flags when we aligned (or did so after with [bamaddrg](https://github.com/ekg/bamaddrg), that's all we need to do to run the joint calling. (NB: due to the amount of data in SRR341549, this should take about 20 minutes.)

### 3.2 `bgzip` and `tabix`
We can speed up random access to VCF files by compressing them with `bgzip`, in the [htslib](https://github.com/samtools/htslib) package. `bgzip` is a "block-based GZIP", which compresses files in chunks of lines. This chunking let's us quickly seek to a particular part of the file, and support indexes to do so. The default one to use is tabix. It generates indexes of the file with the default name `.tbi`.

```
bgzip e_colis.vcf  # makes SRR1770413.vcf.gz
tabix -p vcf e_colis.vcf.gz
```
### 3.3 Take a peek with `vt`
[vt](https://github.com/atks/vt) is a toolkit for variant annotation and manipulation. In addition to other methods, it provides a nice method, `vt peek`, to determine basic statistics about the variants in a VCF file.

We can get a summary like so:
```
vt peek e_colis.vcf.gz
```

### 3.4 Filtering using the transition/transversion ratio (ts/tv) as a rough guide
`vt` produces a nice summary with the transition/transversion ratio. Transitions are mutations that switch between DNA bases that have the same base structure (either a [purine](https://en.wikipedia.org/wiki/Purine) or [pyrimidine](https://en.wikipedia.org/wiki/Pyrimidine) ring).

In most biological systems, [transitions (A<->G, C<->T) are far more likely than transversions](https://upload.wikimedia.org/wikipedia/commons/3/35/Transitions-transversions-v3.png), so we expect the ts/tv ratio to be pretty far from 0.5, which is what it would be if all mutations between DNA bases were random. In practice, we tend to see something that's at least 1 in most organisms, and ~2 in some, such as human. In some biological contexts, such as in mitochondria, we see an even higher ratio, perhaps as much as 20.

As we don't have validation information for our sample, we can use this as a simple guide for our first filtering attempts. An easy way is to try different filterings using `vcffilter` and check the ratio of the resulting set with `vt peek`:

```
# a basic filter to remove low-quality sites
vcffilter -f 'QUAL > 10' e_colis.vcf.gz | vt peek -

# scaling quality by depth is like requiring that the additional log-unit contribution
# of each read is at least N
vcffilter -f 'QUAL / AO > 10' e_colis.vcf.gz | vt peek -
```
