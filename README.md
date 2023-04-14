# somatic_mutations_RNA-seq
GATK pipeline for somatic mutations discovery in RNA-seq data. This pipeline extracts relapse specific mutations from paired (diagnostic & relapse) RNA-seq data.



## Requirements: 

* fastq files: must be located in the folder data/fastq_files/ and named {unit}_1.fastq.gz where {unit} will correspond to the name in the samples_file$Run column. If the name of your files don't correspond with this format you will have to modify the snakemake.smk file acordingly.

* samples_file: This file must contain a column named Run with the fastq file names. Additional columns can be added but they will be omitted. You can change the location and name of this file in the config.yaml file. Bellow you can see an example of this table:


| TARGET.USI | Gender | Age.at.Diagnosis.in.Days | First.Event | Event.Free.Survival.Time.in.Days | Vital.Status | Overall.Survival.Time.in.Days | Protocol | WBC.at.Diagnosis | CNS.Status.at.Diagnosis | Testicular.Involvement | MRD.Day.29 | Bone.Marrow.Site.of.Relapse | CNS.Site.of.Relapse | Testes.Site.of.Relapse | Other.Site.of.Relapse | ETV6.RUNX1.Fusion.Status | TRISOMY.4.10.Status | MLL.Status | TCF3.PBX1.Status | BCR.ABL1.Status | Down.Syndrome | DNA.Index | Cell.of.Origin | ALL.Molecular.Subtype | Phase | Run | Assay_Type | Sample_Name | body_site | sex | Center_Name | Instrument | Library_Name | LoadDate | ReleaseDate | SRA_Study | gap_accession | NumberReadsMapped | NumberSplitReadsMapped | PercReadsMapped | PercReadsMultiMapped | PercReadsTooShort | percBasesTrimmed | percReadsTrimmed | Strandness | Source | PrimaryOrRelapse |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TARGET-10-PASCIU | Male | 795 | Relapse | 735 | Dead | 977 | AALL0232 | 95.1 | CNS 1 | No | 0 | Yes | No | No | No | Negative | Negative | Negative | Unknown | Negative | No | 1 | B-Precursor | None of the above | Phase2_Discovery | SRR1797087 | RNA-Seq | TARGET-10-PASCIU-03A-01R | Primary Blood Derived Cancer - Peripheral Blood | male | BCCAGSC | Illumina HiSeq 2000 | A32609 | 2/10/2020 | 2/10/2015 | SRP011999 | phs000464 | 141303190 | 42536819 | 92.74 | 4.8 | 2.18 | 10.49 | 10.49 | ISR | Peripheral Blood | Primary |
| TARGET-10-PASFXA | Female | 2374 | Relapse | 455 | Dead | 645 | AALL0232 | 260 | CNS 1 | Not applica | 0 | Yes | No | No | No | Negative | Negative | Negative | Positive | Negative | No | 1 | B-Precursor | TCF3-PBX1 | Phase2_Discovery | SRR1791101 | RNA-Seq | TARGET-10-PASFXA-03A-01R | Primary Blood Derived Cancer - Peripheral Blood | female | BCCAGSC | Illumina HiSeq 2000 | A32610 | 2/7/2020 | 2/7/2015 | SRP011999 | phs000464 | 44580878 | 22101395 | 88.78 | 7.19 | 3.9 | 18.95 | 18.95 | ISR | Peripheral Blood | Primary |
| TARGET-10-PASFXA | Female | 2374 | Relapse | 455 | Dead | 645 | AALL0232 | 260 | CNS 1 | Not applica | 0 | Yes | No | No | No | Negative | Negative | Negative | Positive | Negative | No | 1 | B-Precursor | TCF3-PBX1 | Phase2_Discovery | SRR1797089 | RNA-Seq | TARGET-10-PASFXA-04A-01R | Recurrent Blood Derived Cancer - Bone Marrow | female | BCCAGSC | Illumina HiSeq 2000 | A32611 | 2/10/2020 | 2/10/2015 | SRP011999 | phs000464 | 120474383 | 67933949 | 89.16 | 8.4 | 2.32 | 10.82 | 10.82 | ISR | Bone Marrow | Relapse |
| TARGET-10-PAPVTA | Male | 1020 | Relapse | 1012 | Alive | 3217 | AALL0331 | 6.4 | CNS 1 | No | 0.16 | Yes | No | No | No | Negative | Negative | Negative | Negative | Negative | No | 1.11 | B-Precursor | Hyperdiploidy without trisomy of both chromsomes 4 and 10 | Phase2_Discovery | SRR1791019 | RNA-Seq | TARGET-10-PAPVTA-09A-01R | Primary Blood Derived Cancer - Bone Marrow | male | BCCAGSC | Illumina HiSeq 2000 | A32612 | 2/6/2020 | 2/6/2015 | SRP011999 | phs000464 | 142704928 | 25065948 | 94.33 | 3.91 | 1.48 | 14.45 | 14.45 | ISR | Bone Marrow | Primary |



* comparisons: This file must contain the columns named Group, Primary and Relapse and it indicates the samples to compare with the mutect2 algorithm. The columns Primary and Relapse will correspond to the samples listed in the samples_file$Run. The column Group would correspond to the columns Primary_group and Relapse_group pasted together with a "-" (This nomenclature is adopted from and necesary for Majiq analysis). Additional columns can be added but they will be omitted. You can change the location and name of this file in the config.yaml file. Bellow you can see an example of this table:

| Group | Patient | Primary_group | Primary | Relapse_group | Relapse | Primary_Instrument | Relapse_Instrument | Cell_Type |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PAKSWW_Primary-PAKSWW_Relapse | PAKSWW | PAKSWW_Primary | SRR1790984 | PAKSWW_Relapse | SRR1791089 | Illumina HiSeq 2000 | Illumina HiSeq 2000 | B precursor (Non-T, Non-B ALL) |
| PANCVR_Primary-PANCVR_Relapse | PANCVR | PANCVR_Primary | SRR1791069 | PANCVR_Relapse | SRR1790992 | Illumina HiSeq 2000 | Illumina HiSeq 2000 | B-Precursor |
| PANKAK_Primary-PANKAK_Relapse | PANKAK | PANKAK_Primary | SRR1791096 | PANKAK_Relapse | SRR1790994 | Illumina HiSeq 2000 | Illumina HiSeq 2000 | B-Precursor |
| PANSDA_Primary-PANSDA_Relapse | PANSDA | PANSDA_Primary | SRR1791082 | PANSDA_Relapse | SRR1791102 | Illumina HiSeq 2000 | Illumina HiSeq 2000 | B-Precursor |

## Running

You can run the pipeline with:

```bash
snakemake -s workflow/snakemake.smk --profile slurm --use-conda -p
```

If you use the flag --profile you will need a config file in your ~/.config/snakemake/slurm/config.yaml looking like this:

```yaml
jobs: 500
cluster: "sbatch -t {resources.time} --mem={resources.mem}G -n {resources.cpu} -o logs_slurm/{rule}_{wildcards}.o -e logs_slurm/{rule}_{wildcards}.e"
default-resources: [ mem=4, time=360, cpu=1]
#resources: [cpus=30, mem_mb=500000]
```
