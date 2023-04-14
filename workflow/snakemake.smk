configfile: "metadata/config.yaml"

localrules: all

import pandas as pd
import os

# I forget to create the logs folder all the time so it fails to run
logs = "logs_slurm"
# Check whether the specified path exists or not
isExist = os.path.exists(logs)
if not isExist:

   # Create a new directory because it does not exist
   os.makedirs(logs)
   print("The logs_slurm directory was created!")

# I forget to create the logs folder all the time so it fails to run
tmp = "tmp_files"
# Check whether the specified path exists or not
isExist = os.path.exists(tmp)
if not isExist:

   # Create a new directory because it does not exist
   os.makedirs(tmp)
   print("The tmp_files directory was created!")



units_table = pd.read_table(config["samples_file"], sep="\t").set_index("Run", drop=False)
groups=pd.read_csv(config["comparisons"], sep ="\t")

rule all:
	input:
		expand("results/mutect2/{comparison}_relapse_mutations_filtered.funcotated.maf",comparison=groups.Group)


rule STAR_align:
	input:
		files=lambda wildcards: expand("data/fastq_files/{{unit}}_{num}.fastq.gz", unit=units_table.Run, num=[1,2]),
		genome=config["STAR_genome"]
	params:
		path="data/bam_files/{unit}_"
	resources:
		cpu=10,
		mem=lambda wildcards, attempt: attempt * 120,
		time = "32:00:00"
	conda:
		"envs/Star.yaml"
	output:
		"data/bam_files/{unit}_Aligned.sortedByCoord.out.bam"
	shell:
		"STAR --genomeDir {input.genome} --readFilesIn {input.files} "
		"--twopassMode Basic "
		"--outTmpKeep None "
		" --readFilesCommand zcat "
		"--runThreadN {resources.cpu} "
		"--outSAMtype BAM SortedByCoordinate "
		"--outFileNamePrefix {params.path} "
		"--alignSJoverhangMin 8 "
		"--limitBAMsortRAM {resources.mem}000000000 --outSAMattributes All "
		"--quantMode GeneCounts"

	

rule samtools_index:
	input:
		"data/bam_files/{unit}_Aligned.sortedByCoord.out.bam"
	output:
		"data/bam_files/{unit}_Aligned.sortedByCoord.out.bam.bai"
	conda:
		"envs/SamTools_env.yaml"
	resources:
		cpu=10,
		mem=lambda wildcards, attempt: attempt * 10,
		time = "32:00:00"
	shell:
		"samtools index -@ {resources.cpu} {input} {output}"


rule picard:
	input:
		"data/bam_files/{unit}_Aligned.sortedByCoord.out.bam",
		"data/bam_files/{unit}_Aligned.sortedByCoord.out.bam.bai"
	output:
		bam="data/modified_bam_files/{unit}_Aligned.sortedByCoord.out.marked.bam",
		metrics="data/modified_bam_files/{unit}_metrics.txt"
	resources:
		cpu=1,
		mem=lambda wildcards, attempt: attempt * 50
	conda: 
		"envs/picards_env.yaml"
	shell:
		"picard -Xmx{resources.mem}g MarkDuplicates -MAX_RECORDS_IN_RAM 50000 -I {input[0]} -O {output.bam} -M {output.metrics}"


rule SplitNCigarReads:
	input:
		bam="data/modified_bam_files/{unit}_Aligned.sortedByCoord.out.marked.bam",
		genome=config["fasta_genome"]
	output:"data/modified_bam_files/{unit}_Aligned.sortedByCoord.out.marked.splited.bam"
	resources:
		cpu=1,
		mem=lambda wildcards, attempt: attempt * 10,
		time = "32:00:00"
	conda:
		"envs/gatk4_env.yaml"
	shell:
		" gatk --java-options \"-Xmx{resources.mem}G -Djava.io.tmpdir=`pwd`/tmp_files\" SplitNCigarReads --tmp-dir tmp_files -OBI -R {input.genome} -I {input.bam} -O {output}"

rule add_ReadGroups:
	input:
		"data/modified_bam_files/{unit}_Aligned.sortedByCoord.out.marked.splited.bam"
	conda: 
		"envs/picards_env.yaml"
	output:"data/modified_bam_files/{unit}_Aligned.sortedByCoord.out.marked.splited.renamed.bam"
	resources:
		cpu=1,
		mem=lambda wildcards, attempt: attempt * 10,
		time = "32:00:00"
	shell:
		"picard AddOrReplaceReadGroups "
		"I={input} "
		"O={output} "
		"RGID={wildcards.unit} "
		"RGLB={wildcards.unit} "
		"RGPL=illumina "
		"RGPU={wildcards.unit} "
		"RGSM={wildcards.unit}"	


rule BaseRecalibrator:
	input:
		bam="data/modified_bam_files/{unit}_Aligned.sortedByCoord.out.marked.splited.renamed.bam",
		variations=config["variations"],
		genome=config["fasta_genome"]
	output:
		"data/modified_bam_files/{unit}.recal_data.txt"
	resources:
		cpu=1,
		mem=lambda wildcards, attempt: attempt * 10,
		time = "32:00:00"
	conda:
		"envs/gatk4_env.yaml"
	shell:
 		"gatk --java-options \"-Xmx{resources.mem}G -Djava.io.tmpdir=`pwd`/tmp_files\" BaseRecalibrator --tmp-dir tmp_files -I {input.bam} -R {input.genome} --known-sites {input.variations} -O {output}"


rule ApplyBQSR:
	input:
		bam="data/modified_bam_files/{unit}_Aligned.sortedByCoord.out.marked.splited.renamed.bam",
		variations="data/modified_bam_files/{unit}.recal_data.txt",
		genome=config["fasta_genome"]
	output:
		"data/modified_bam_files/{unit}_Aligned.sortedByCoord.out.marked.splited.recalibrated.bam"
	resources:
		cpu=4,
		mem=lambda wildcards, attempt: attempt * 10,
		time = "32:00:00"
	benchmark:
		"benchmarks/ApplyBQSR/{unit}_benchmark.txt"
	conda:
		"envs/gatk4_env.yaml"
	shell:
		"gatk --java-options \"-Xmx{resources.mem}G -Djava.io.tmpdir=`pwd`/tmp_files\" ApplyBQSR --tmp-dir tmp_files -OBI -R {input.genome} -I {input.bam} --bqsr-recal-file {input.variations} -O {output}"


rule mutect2:
	input:
		genome=config["fasta_genome"],
		normal_mutect2_files=lambda wildcards: expand(
 			'data/modified_bam_files/{sample}_Aligned.sortedByCoord.out.marked.splited.recalibrated.bam',
 			sample=groups.Primary[groups.Group == wildcards.comparison]),
 		tumor_mutect2_files=lambda wildcards: expand(
 			'data/modified_bam_files/{sample}_Aligned.sortedByCoord.out.marked.splited.recalibrated.bam',
 			sample=groups.Relapse[groups.Group == wildcards.comparison])
	resources:
		cpu=1,
		mem=lambda wildcards, attempt: attempt * 10,
		time = "32:00:00"
	benchmark:
		"benchmarks/mutect2/{comparison}_benchmark.txt"
	conda:
		"envs/gatk4_env.yaml"
	params:
		normal_name=lambda wildcards: expand("{primary_name}",primary_name=groups.Primary[groups.Group == wildcards.comparison].unique())
	output:
		"results/mutect2/{comparison}_relapse_mutations.vcf.gz"
	shell:
		"gatk --java-options \"-Xmx{resources.mem}G -Djava.io.tmpdir=`pwd`/tmp_files\" "
		"Mutect2 --tmp-dir tmp_files -R {input.genome} -I {input.tumor_mutect2_files} "
		"-I {input.normal_mutect2_files} "
		"-normal {params.normal_name} -O {output}"


rule FilterMutectCalls:
	input:
		genome=config["fasta_genome"],
		mutations="results/mutect2/{comparison}_relapse_mutations.vcf.gz"
	resources:
		cpu=4,
		mem=lambda wildcards, attempt: attempt * 10,
		time = "32:00:00"
	conda:
		"envs/gatk4_env.yaml"
	benchmark:
		"benchmarks/FilterMutectCalls/{comparison}_benchmark.txt"
	output:
		"results/mutect2/{comparison}_relapse_mutations_filtered.vcf.gz"
	shell:
		"gatk --java-options \"-Xmx{resources.mem}G -Djava.io.tmpdir=`pwd`/tmp_files\" "
		"FilterMutectCalls --tmp-dir tmp_files "
   		"-R {input.genome} "
   		"-V {input.mutations} "
   		"-O {output}"


rule Funcotator:
	input:
		variants="results/mutect2/{comparison}_relapse_mutations_filtered.vcf.gz",
		source=config["data_source"],
		genome=config["fasta_genome"]
	params:
		ref_version=config["genome_version"]
	resources:
		cpu=4,
		mem=lambda wildcards, attempt: attempt * 10,
		time = "32:00:00"
	conda:
		"envs/gatk4_env.yaml"
	benchmark:
		"benchmarks/Funcotator/{comparison}_benchmark.txt"
	output:
		"results/mutect2/{comparison}_relapse_mutations_filtered.funcotated.maf"
	shell:
		"gatk --java-options \"-Xmx{resources.mem}G -Djava.io.tmpdir=`pwd`/tmp_files\" Funcotator "
		"--tmp-dir tmp_files "
		"--variant {input.variants} "
		"--reference {input.genome} "
		"--ref-version {params.ref_version} "
		"--data-sources-path {input.source} "
		"--output {output} "
		"--output-file-format MAF"
