unfiltered_psl=snakemake.input.unfiltered_psl
filtered_psl=open(snakemake.output.filtered_psl, 'w')

best_dict={}
for line in open(unfiltered_psl):
	split_line=line.strip().split('\t')
	print('split line is', split_line)
	if len(split_line)>5 and split_line[0].isdigit():
		score, key=int(split_line[0]), split_line[9]
		if key not in best_dict or score>int(best_dict[key][0][0]):
			best_dict[key]=[split_line]
		elif score==int(best_dict[key][0][0]):
			best_dict[key].append(split_line)
	else:
		filtered_psl.write(line)

for key in best_dict:
	for tied_hit in best_dict[key]:
		print('hit is', tied_hit)
		filtered_psl.write('\t'.join(tied_hit)+'\n')
