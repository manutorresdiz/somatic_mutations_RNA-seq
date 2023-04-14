sample = snakemake.params["samples"]
genome = snakemake.params["genome"]

f = open("./metadata/majiq_configs/"+sample+"_majiq_config_file.txt","w")
f.write("[info]\n")
f.write("bamdirs=./data/bam_files\n")
f.write("genome="+genome+"\n")
f.write("[experiments]\n")

f.write(sample+'='+sample+'_Aligned.sortedByCoord.out\n')
