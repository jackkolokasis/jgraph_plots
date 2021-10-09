# Awk script to produce jgraph source
# file in order to plot iostat CPU time
# stacked bars. To use:
#
# cat input_file | awk -f <script_name> | /path/to/jgraph -P | ps2pdf - > plot.pdf
#
# or
#
# cat input_file | awk -f <script_name> | /path/to/jgraph > plot.eps
#
# Both output types can be directly included in LaTeX documents
#
# Input file structure, note
# the blank lines because they work
# as record separators
# ===============================
# <Graph Title>
#
# <1st Configuration Name>
#
# <bar data 1>
#
# <bar data 2>
#
# ....
#
# <bar data n>
#
# <2nd Configuration Name>
#
# <bar data>
#
# ...
#================================
#
# Bar data structure
#================================
# <Bar Label>
# <Execution Time>
# <User Time Percentage>
# <System Time Percentage>
# <Iowait Time Percentage>
# <Idle Time Percentage>
#================================

BEGIN {
	getline;
	graph_title = $0
	exec_time_max = 0
	nr_configs = 0
	plot_index = 0
	total_plots = 0
	RS = ""
	FS = "\n"
}

{
	if(NF == 1){
		hash_label[nr_configs] = $0
		grouped_bars[nr_configs] = 0
		nr_configs++
		plot_index = 0
	}else{
		exec_time = $2
		user_time = $3
		system_time = $4
		iowait_time = $5
		idle_time = $6

		if(exec_time > exec_time_max)
			exec_time_max = exec_time;

		exec_time_arr[nr_configs - 1][plot_index] = exec_time
		mark_label[nr_configs - 1][plot_index] = $1
		userbox[nr_configs -1][plot_index] = exec_time * user_time / 100
		systembox[nr_configs - 1][plot_index] = exec_time * system_time / 100
		iowaitbox[nr_configs - 1][plot_index] = exec_time * iowait_time / 100
		idlebox[nr_configs - 1][plot_index] = exec_time * idle_time / 100

		grouped_bars[nr_configs - 1]++
		plot_index++
		total_plots++

	}
}

END {
	print "newgraph"
	# Graph Title, edit placement to your liking
	printf("title hjc vjc x %.2f y %.2f : %s\n", total_plots / 2, exec_time_max + exec_time_max / 5, graph_title);
	# Edit x and y placement to your liking
	printf("yaxis min 0 max %.0f hash 50 mhash 1 label : Execution Time(sec)\n", exec_time_max + (50 - (exec_time_max % 50)));
	printf("xaxis min 0 max %.2f no_auto_hash_marks no_auto_hash_labels label : Threads\n",
	       total_plots + 0.4);
	#printf("newline gray 0 pts 0 0 %.2f 0\n", total_plots + 0.4);
	#printf("xaxis hash_labels fontsize 8 rotate 45\n");
	#print "clip"

	plot_index = 1.0;
	for(i = 0; i < nr_configs; i++){
		plot_index_initial = plot_index;
		max_among_grouped_bars = 0;
		for(j = 0; j < grouped_bars[i]; j++){
			# fill goes from black (0) to white (1), grayscale
			# Can also change to cfill and add rgb values from 0 to 1
			# pattern can be solid, stripe or estripe (mostly the same with stripe, don't bother)
			# stripe accepts degrees parameter
			# Bar width hardcoded to 0.4 (first parameter of marksize, units computed relative to x axis points), 
			# feel free to modify
			printf("newcurve marktype box marksize %.2f %.2f fill 0 pattern stripe 180\n",
			       0.4, idlebox[i][j]);
			printf("pts %.2f %.2f\n", plot_index, userbox[i][j] + systembox[i][j] + iowaitbox[i][j] + idlebox[i][j] / 2);

			printf("newcurve marktype box marksize %.2f %.2f fill 0.5 pattern stripe -45\n",
			       0.4, iowaitbox[i][j]);
			printf("pts %.2f %.2f\n", plot_index, userbox[i][j] + systembox[i][j] + iowaitbox[i][j] / 2);

			printf("newcurve marktype box marksize %.2f %.2f fill 0.75 pattern stripe 45\n",
			       0.4, systembox[i][j]);
			printf("pts %.2f %2f\n", plot_index, userbox[i][j] + systembox[i][j] / 2);

			printf("newcurve marktype box marksize %.2f %.2f fill 0.25\n",
			       0.4, userbox[i][j]);
			printf("pts %.2f %.2f\n", plot_index, userbox[i][j]/2);

			printf("xaxis hash_label at %.2f : %s\n", plot_index, mark_label[i][j]);

			if(exec_time_arr[i][j] > max_among_grouped_bars)
				max_among_grouped_bars = exec_time_arr[i][j]
			plot_index += 0.5;
		}
		# Configuration name
		printf("newstring fontsize 7 hjc vjc x %.2f y %.2f : %s\n", (plot_index + plot_index_initial) / 2 - (i ? 0.1 : 0.3),
		       max_among_grouped_bars + max_among_grouped_bars / 15, hash_label[i]);
		plot_index += 0.6;
	}

	# Legend, style corresponds to bars above so modify both together
	print "copygraph xaxis nodraw yaxis nodraw\n"
	printf("legend x %d y %.2f\n", plot_index + 1, exec_time_max / 2);
	print "newcurve marktype box fill 0 pattern stripe 180 marksize 0.4", exec_time_max / 20, "\n",
	      "label : Idle Time\n",
	      "newcurve marktype box fill 0.5 pattern stripe -45 marksize 0.4", exec_time_max / 20, "\n",
	      "label : Iowait Time\n",
	      "newcurve marktype box fill 0.75 pattern stripe 45 marksize 0.4", exec_time_max / 20, "\n",
	      "label : System Time\n",
	      "newcurve marktype box fill 0.25 marksize 0.4", exec_time_max / 20, "\n",
	      "label : User Time"
}
