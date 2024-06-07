# Code for genome preprocessing, assembly, polishing, and evaluation

## Data preprocessing

```bash
sample=HG002

## ONT filtering with Filtlong

targetLongReadCov=100
genomeSize=3000000000
targetBases=$(( ${targetLongReadCov} * ${genomeSize} ))

filtlong \
   --min_length 1000 \
   --keep_percent 90 \
   --length_weight 0.5 \
   --target_bases ${targetBases} \
   ${sample}.ont.raw.fastq > ${sample}.ont.filtered.fastq

## ONT read correction using Illumina short-reads by means of Ratatosk

lr=lr-fastq.txt # Text file with ONT fastq path
sr=sr-fastqs.txt # Text file with Illumina R1 and R2 fastq paths

Ratatosk correct \
   -s ${sr} \
   -l ${lr} \
   -o ${sample}.filtered.corrected
```

## Read quality assessment

```bash
sample=HG002

## Assessing Illumina reads using FastQC

fastqc \
   ${sample}_R1.fastq.gz \
   -o fastqc_dir

fastqc \
   ${sample}_R2.fastq.gz \
   -o fastqc_dir


## Assessing ONT reads using NanoPlot

### Raw ONT reads
NanoPlot \
   --threads 16 \
   --verbose \
   --fastq ${sample}.ont.raw.fastq \
   --outdir NanoPlot_raw_reads

### Filtered ONT reads
NanoPlot \
   --threads 16 \
   --verbose \
   --fastq ${sample}.ont.filtered.fastq \
   --outdir NanoPlot_filtered_reads

### Filtered and corrected ONT reads
NanoPlot \
   --threads 16 \
   --verbose \
   --fastq ${sample}.ont.filtered.corrected.fastq \
   --outdir NanoPlot_corrected_reads
```

## Assembly process

```bash
sample=HG002


## ###### ##
## Shasta ##
## ###### ##

### Assembly filtered reads
.../shasta-Linux-0.9.0 \
   --command assemble \
   --input ${sample}.ont.filtered.fastq \
   --assemblyDirectory Shasta_filt-reads \
   --conf Nanopore-Oct2021

mv Shasta_filt-reads/Assembly.fasta ${sample}.filt.shasta.fasta

### Assembly filtered and corrected reads
.../shasta-Linux-0.9.0 \
   --command assemble \
   --input ${sample}.ont.filtered.corrected.fastq \
   --assemblyDirectory Shasta_corr-reads \
   --conf Nanopore-Oct2021

mv Shasta_corr-reads/Assembly.fasta ${sample}.corr.shasta.fasta

## #### ##
## Flye ##
## #### ##

### Assembly filtered reads
flye \
   --nano-raw ${sample}.ont.filtered.fastq \
   --out-dir Flye_filt-reads \
   --genome-size "3.2g" \
   --iterations 2

mv Flye_filt-reads/Assembly.fasta ${sample}.filt.flye.fasta

### Assembly filtered and corrected reads
flye \
   --nano-corr ${sample}.ont.filtered.corrected.fastq \
   --out-dir Flye_corr-reads \
   --genome-size "3.2g" \
   --iterations 2

mv Flye_corr-reads/Assembly.fasta ${sample}.corr.flye.fasta

## ##### ##
## Raven ##
## ##### ##

### Assembly filtered reads
raven ${sample}.ont.filtered.fastq.gz > ${sample}.filt.raven.fasta

### Assembly filtered and corrected reads
raven ${sample}.ont.filtered.corrected.fastq.gz > ${sample}.corr.raven.fasta

## ###### ##
## wtdbg2 ##
## ###### ##

### Assembly filtered reads
wtdbg2 \
   -x ont \
   -g "3.2g" \
   -i ${sample}.ont.filtered.fastq \
   -fo ${sample}.ont.filt.wtdbg2

wtpoa-cns \
   -i ${sample}.ont.filt.wtdbg2.ctg.lay.gz
   -fo ${sample}.ont.filt.wtdbg2.fasta

### Assembly filtered and corrected reads
wtdbg2 \
   -x ont \
   -g "3.2g" \
   -i ${sample}.ont.filtered.corrected.fastq \
   -fo ${sample}.ont.corr.wtdbg2

wtpoa-cns \
   -i ${sample}.ont.corr.wtdbg2.ctg.lay.gz
   -fo ${sample}.ont.corr.wtdbg2.fasta
```

## Polishing

```bash
## Polishing Filtered+Corrected Flye assembly by:
### 1. Two rounds of Racon
### 2. Medaka
### 3. Pilon

sample=HG002

## ############### ##
## Racon (Round 1) ##
## ############### ##

minimap2 \
   -x map-ont \
   ${sample}.corr.flye.fasta \
   ${sample}.filtered.corrected.fastq.gz > ${sample}.corr.flye.racon1.paf

racon \
   -m 8 -x -6 -g -8 -w 500 \
   ${sample}.filtered.corrected.fastq.gz \
   ${sample}.corr.flye.racon1.paf \
   ${sample}.corr.flye.fasta > ${sample}.corr.flye.racon1.fasta

## ############### ##
## Racon (Round 2) ##
## ############### ##

minimap2 \
   -x map-ont \
   ${sample}.corr.flye.racon1.fasta \
   ${sample}.filtered.corrected.fastq.gz > ${sample}.corr.flye.racon2.paf

racon \
   -m 8 -x -6 -g -8 -w 500 \
   ${sample}.filtered.corrected.fastq.gz \
   ${sample}.corr.flye.racon2.paf \
   ${sample}.corr.flye.racon1.fasta > ${sample}.corr.flye.racon2.fasta

## ###### ##
## Medaka ##
## ###### ##

medaka_consensus \
   -i ${sample}.filtered.corrected.fastq.gz \
   -d ${sample}.corr.flye.racon2.fasta \
   -o Medaka_Results \
   -m r941_prom_hac_g507

mv Medaka_Results/consensus.fasta ${sample}.corr.flye.racon2.medaka.fasta

## ##### ##
## Pilon ##
## ##### ##

### 0. Index Fasta
gatk CreateSequenceDictionary -R ${sample}.corr.flye.racon2.medaka.fasta
bwa index ${sample}.corr.flye.racon2.medaka.fasta
samtools faidx ${sample}.corr.flye.racon2.medaka.fasta

### 1. FastqsToUnmappedBam
id=${sample}
lb="I-${sample}-1"
pl="ILLUMINA"
sc="GIAB"

gatk FastqToSam \
  -F1 ${sample}_R1.fastq.gz \
  -F2 ${sample}_R2.fastq.gz \
  -O ${sample}.unmapped.bam \
  -RG ${id} \
  -LB ${lb} \
  -PL ${pl} \
  -CN ${sc}

### 2. MarkIlluminaAdapters
gatk MarkIlluminaAdapters \
  -I ${sample}.unmapped.bam \
  -M ${outdir}/${sample}.unmapped.markilluminaadapters.metrics \
  -O ${sample}.unmapped.markilluminaadapters.bam \
  --ADAPTERS PAIRED_END

### 3. AlignBam
gatk SamToFastq \
  -I ${sample}.unmapped.markilluminaadapters.bam \
  -F ${sample}.unmapped.markilluminaadapters.fastq \
  --CLIPPING_ATTRIBUTE XT \
  --CLIPPING_ACTION 2 \
  --INTERLEAVE true \
  --INCLUDE_NON_PF_READS true

bwa mem \
   -K 100000000 -p -v 3 -t 16 -Y \
   ${sample}.corr.flye.racon2.medaka.fasta \
   ${sample}.unmapped.markilluminaadapters.fastq > ${sample}.mapped.sam

gatk MergeBamAlignment \
  -ALIGNED ${sample}.mapped.sam \
  -UNMAPPED ${sample}.unmapped.bam \
  -O ${sample}.merged.bam \
  -R ${sample}.corr.flye.racon2.medaka.fasta \
  -SO "unsorted" \
  --CREATE_INDEX true \
  -MC true \
  --CLIP_ADAPTERS false \
  --CLIP_OVERLAPPING_READS true \
  --INCLUDE_SECONDARY_ALIGNMENTS true \
  --MAX_INSERTIONS_OR_DELETIONS -1 \
  --PRIMARY_ALIGNMENT_STRATEGY MostDistant \
  --ATTRIBUTES_TO_RETAIN XS

### 4. MarkDuplicates
gatk MarkDuplicates \
  -I ${sample}.merged.bam \
  -O ${sample}.bam \
  -M ${sample}.MarkDuplicates.metrics.txt \
  --REMOVE_DUPLICATES false \
  --OPTICAL_DUPLICATE_PIXEL_DISTANCE 2500 \
  --VALIDATION_STRINGENCY SILENT \
  --ASSUME_SORT_ORDER queryname \
  --CREATE_MD5_FILE true \
  --CLEAR_DT false

### 5. SortSam and FixTags
gatk SortSam \
  -I ${sample}.bam \
  -O ${sample}.merged.deduped.sorted.bam \
  -SO coordinate \
  --CREATE_INDEX true \
  --CREATE_MD5_FILE true

gatk SetNmMdAndUqTags \
  -I ${sample}.merged.deduped.sorted.bam \
  -O ${sample}.merged.deduped.sorted.fixed.bam \
  -R ${sample}.corr.flye.racon2.medaka.fasta \
  --CREATE_INDEX true \
  --CREATE_MD5_FILE true

### 6. Run Pilon:

bam=${outdir}/${sample}.merged.deduped.sorted.fixed.bam
fasta=${workdir}/assembly/Assembly_Flye_1_filt-reads/Polishing_Racon/${sample}.filt.flye.racon2.fasta

pilon=~/anaconda3/envs/pilon/share/pilon-1.24-0/pilon.jar

java -Xmx512G -jar .../pilon-1.24-0/pilon.jar \
   --genome ${sample}.corr.flye.racon2.medaka.fasta \
   --frags ${sample}.merged.deduped.sorted.fixed.bam \
   --output ${sample}.corr.flye.racon2.medaka.pilon \
   --outdir Pilon_Results
```

## Contig curation, scaffolding, and gap-filling

```bash
## 1. Contig curation with purge_dups
## 2. Scaffolding with RagTag
## 3. Gap-filling con TGS-GapCloser

sample=HG002

reference=chm13v2.0.fa

## ########## ##
## purge_dups ##
## ########## ##

pdconfig=/path/to/purge_dups/scripts/pd_config.py
run_purge_dups=/path/to/purge_dups/scripts/run_purge_dups.py
bindir=/path/to/purge_dups/bin

# Step 1. Use pd_config.py to generate a configuration file.
lr=lr-fastq.txt # Text file with ONT filtered and corrected fastq path
sr=sr-fastqs.txt # Text file with Illumina R1 and R2 fastq paths

config=${sample}.purge_dups.config.json
${pdconfig} -s ${sr} -l ${outdir} -n ${config} ${sample}.corr.flye.racon2.pilon.fasta ${lr}

# Step 2. Modify the configuration file (optional).
### Change '"skip": 0' to '"skip": 1' in "busco" and "kcp".
### nano ${outdir}/HG002.purge_dups.config.json

# Step 3. Use run_purge_dups.py to run the pipeline.
spid=${sample}
${run_purge_dups} -p bash ${config} ${bindir} ${spid}

mv ${sample}.flye.racon2.pilon/seqs/${sample}.flye.racon2.pilon.purged.fa ${sample}.corr.flye.racon2.pilon.purged.fasta

## ###### ##
## RagTag ##
## ###### ##

# 1. Misassemblies correction
ragtag.py correct -o . ${reference} ${sample}.corr.flye.racon2.pilon.purged.fasta

mv ragtag.correct.fasta ${sample}.corr.flye.racon2.pilon.purged.corrected.fasta

# 2. Scaffolding
ragtag.py scaffold -o . ${reference} ${sample}.corr.flye.racon2.pilon.purged.corrected.fasta

mv ragtag.scaffold.fasta ${sample}.corr.flye.racon2.pilon.purged.corrected.scaffold.fasta

## ############# ##
## TGS-GapCloser ##
## ############# ##

reads=${sample}.filtered.corrected.fastq
reads_fasta=${sample}.filtered.corrected.fasta

# Convert FASTQ to FASTA
seqtk seq -a ${reads} > ${reads_fasta}

# Run TGS-GapClosed
outprefix=./${sample}

tgsgapcloser \
    --thread 16 \
    --ne \
    --minmap_arg ' -x map-ont -K 80M' \
    --tgstype ont \
    --scaff ${sample}.corr.flye.racon2.medaka.pilon.purged.corrected.scaffold.fasta \
    --reads ${reads_fasta} \
    --output ${outprefix}

mv ${sample}.scaff_seqs ${sample}.corr.flye.racon2.pilon.purged.corrected.scaffold.gapclosed.fasta

```

## Assembly evaluation

```bash
## 1. QUAST
## 2. BUSCO
## 3. Merqury

sample=HG002

final_assembly=${sample}.corr.flye.racon2.medaka.pilon.purged.corrected.scaffold.gapclosed.fasta

reference=chm13v2.0.fa

## ##### ##
## QUAST ##
## ##### ##

quast-lg.py \
    --threads ${threads} \
    --circos \
    --output-dir ${outdir} \
    --reference ${reference} \
    --labels ${sample}_final_assembly \
    ${final_assembly}

## ##### ##
## BUSCO ##
## ##### ##

busco \
    -m genome \
    -i ${final_assembly} \
    -o ${sample}_final_assembly \
    --out_path ${outdir} \
    -l primates_odb10

## ####### ##
## Merqury ##
## ####### ##

meryldir=./meryl_files
if [ ! -d ${meryldir} ]; then
  mkdir -p ${meryldir}
fi

r1meryl=${meryldir}/${sample}_R1.meryl
r2meryl=${meryldir}/${sample}_R2.meryl
merylgenome=${meryldir}/${sample}.meryl

# Recommended k-value
k=21

# 1. Build meryl dbs
meryl k=${k} count output ${r1meryl} ${r1}
meryl k=${k} count output ${r2meryl} ${r2}

# 2. Merge
meryl union-sum output ${merylgenome} ${meryldir}/${sample}_R*.meryl

# 3. Running Merqury
prefix=MerquryEval
resultsdir=./merqury_results
if [ ! -d ${resultsdir} ]; then
  mkdir -p ${resultsdir}
fi

cd ${resultsdir}

merqury.sh ${merylgenome} ${final_assembly} ${prefix}

```
