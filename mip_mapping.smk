configfile: 'mip_mapping.yaml'
rule all:
	input:
		big_psl=config['genome_name']+'_'+config['prefix']+'_MIP_capture_sequences.bb'

rule make_fasta:
	input:
		mip_info_file=config['mip_info_csv']
	output:
		mip_fasta='intermediate_outputs/{prefix}_MIP_capture_sequences.fa'
	run:
		mip_table=[line.strip().split(',') for line in open(input.mip_info_file)][1:]
		output_file=open(output.mip_fasta, 'w')
		paired_list=[[line[15], line[12]] for line in mip_table]
		for name, seq in paired_list:
			output_file.write('>'+name+'\n')
			output_file.write(seq+'\n')

rule fasta_to_twobit:
	input:
		genome_fasta=config['genome_fasta']
	output:
		genome_2bit='intermediate_outputs/{genome_name}.2bit'
	shell:
		'faToTwoBit {input.genome_fasta} {output.genome_2bit}'

rule get_twobit_info:
	input:
		genome_2bit='intermediate_outputs/{genome_name}.2bit'
	output:
		twobit_info='intermediate_outputs/{genome_name}.chrom.sizes'
	shell:
		'twoBitInfo {input.genome_2bit} stdout | sort -k2rn > {output.twobit_info}'

rule blat_fasta:
	input:
		mip_fasta='intermediate_outputs/{prefix}_MIP_capture_sequences.fa',
		genome=config['genome_fasta']
	output:
		mip_psl='intermediate_outputs/{prefix}_unfiltered_MIP_capture_sequences.psl'
	shell:
		'blat {input.genome} {input.mip_fasta} {output.mip_psl}'

rule filter_best_mappers:
	input:
		unfiltered_psl='intermediate_outputs/{prefix}_unfiltered_MIP_capture_sequences.psl'
	output:
		filtered_psl='intermediate_outputs/{prefix}_filtered_MIP_capture_sequences.psl'
	script:
		'filter_best_mappers.py'

rule psl_to_big_psl_input:
	input:
		filtered_psl='intermediate_outputs/{prefix}_filtered_MIP_capture_sequences.psl'
	output:
		unsorted_big_psl_input='intermediate_outputs/{prefix}_filtered_MIP_capture_sequences.bigPslInput'
	shell:
		'pslToBigPsl {input.filtered_psl} {output.unsorted_big_psl_input}'

rule sort_psl_file:
	input:
		unsorted_big_psl_input='intermediate_outputs/{prefix}_filtered_MIP_capture_sequences.bigPslInput'
	output:
		sorted_big_psl_input='intermediate_outputs/{prefix}_filtered_MIP_capture_sequences_sorted.bigPslInput'
	shell:
		'LC_COLLATE=C sort -k1,1 -k2,2n {input.unsorted_big_psl_input} > {output.sorted_big_psl_input}'

rule download_as_file:
	output:
		downloaded_as_file='intermediate_outputs/bigPsl.as'
	params:
		prefix='intermediate_outputs'
	shell:
		'wget --directory-prefix {params.prefix} https://genome.ucsc.edu/goldenpath/help/examples/bigPsl.as'

rule big_psl_input_to_big_psl:
	input:
		sorted_bgp_input='intermediate_outputs/{prefix}_filtered_MIP_capture_sequences_sorted.bigPslInput',
		chrom_sizes='intermediate_outputs/{genome_name}.chrom.sizes',
		as_file='intermediate_outputs/bigPsl.as'
	output:
		big_psl='{genome_name}_{prefix}_MIP_capture_sequences.bb'
	shell:
		'bedToBigBed -type=bed12+13 -tab -as={input.as_file} {input.sorted_bgp_input} {input.chrom_sizes} {output.big_psl}'
