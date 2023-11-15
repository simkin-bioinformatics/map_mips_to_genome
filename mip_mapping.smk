rule all:
	input:
		filtered_psl='filtered_capture_sequences.psl'

rule make_fasta:
	input:
		mip_info_file='mip_info.csv'
	output:
		mip_fasta='capture_sequences.fa'
	run:
		mip_table=[line.strip().split(',') for line in open(input.mip_info_file)][1:]
		output_file=open(output.mip_fasta, 'w')
		paired_list=[[line[15], line[12]] for line in mip_table]
		for name, seq in paired_list:
			output_file.write('>'+name+'\n')
			output_file.write(seq+'\n')

rule blat_fasta:
	input:
		mip_fasta='capture_sequences.fa',
		genome='/home/alfred/other_people/charlie/make_assembly_hub_plus_annotations/data/p_vivax.fa'
	output:
		mip_psl='capture_sequences.psl'
	shell:
		'blat {input.genome} {input.mip_fasta} {output.mip_psl}'

rule filter_best_mappers:
	input:
		unfiltered_psl='capture_sequences.psl'
	output:
		filtered_psl='filtered_capture_sequences.psl'
	script:
		'filter_best_mappers.py'
