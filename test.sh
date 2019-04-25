#!/bin/bash 

#wrapper for snp and gene queries
if [[ "$1" =~ ^(([Hh]$|[Hh][Ee][Ll][Pp])|)$ ]]; then
    echo -ne "Please see how to use the script.\n 
        eg: test.sh get-rsid -i test_in.txt -o test_out txt -g hg19\n
        MODULES:\n
        get-rsid:\tgets rsIDs given chr and pos..\n
        get-snp-coord:\tgets snp coordinates given rsID\n
        get-gene-id:\tgets HGNC symbol of gene containing given start and end coordinates\n
	get-gene-coord:\tgets transcription start and end of a gene, given hgnc symbols\n
	get-rsid-and-geneid: gets rsID of SNPs and genes they lie in, given chr and pos\n
	get-nearby-genes:\t gets genes in the user defined vicinity of a given position or rsID\n";
	exit 1;
else
      opt="$1"
      case "$opt" in
        "get-rsid") 
		#tocall="/scratch/sk752/dbsnp_files/snp_and_gene_module/fetch_rsid.sh";;
		tocall="/scratch/sk752/dbsnp_files/snp_and_gene_module/fetch_rsid_faster.sh";;
        "get-snp-coord") 
		tocall="/scratch/sk752/dbsnp_files/snp_and_gene_module/fetch-snp-chr-and-pos.sh";;
        "get-gene-id")
		tocall="/scratch/sk752/dbsnp_files/snp_and_gene_module/fetch-gene.sh";;
	"get-gene-coord")
		tocall="/scratch/sk752/dbsnp_files/snp_and_gene_module/fetch-gene-coord.sh";;
	"get-rsid-and-geneid") 
		tocall="/scratch/sk752/dbsnp_files/snp_and_gene_module/fetch-rsid-and-gene.sh";;
	"get-nearby-genes")
		tocall="/scratch/sk752/dbsnp_files/snp_and_gene_module/fetch-nearby-genes.sh";;
        * ) 
		echo "ERROR: Invalid module: \""$opt"\"" >&2
                exit 1;;
      esac

	shift;
	while [[ $# -gt 0 ]]; do
     		opt="$1";
		shift;
		case "$opt" in
	        "-i"|"--input") 
        	        in_list="$1";
			shift;
			if [[ "$in_list" == "" ]]; then
			    echo -ne "ERROR: Option -i requires an argument. \n" >&2
			    exit 1
	 		fi
		;;
		"-o"|"--output")
                	out_file="$1";
			shift;
		;;
		"-g"|"--genome-build")
                	genome_build="$1";
			shift;
			case "$genome_build" in
				"hg19"|"37"|"GRCh37")
					genome_build="hg19";;
				"hg38"|"38"|"GRCh38")
					genome_build="hg38";;
				* ) 
					echo -ne "ERROR: Invalid genome build. Valid options:\nhg19\nhg38\n19\n38\nGRCh37\nGRCh38\n" >&2
					exit 1 ;;
			esac
		;;
		"-w"|"--window")
			window="$1"
			shift;
			if [[ "$opt" != "get-nearby-genes" ]]
			then
				echo "ERROR: Invalid argument: \""$win"\"" >&2
				exit 1
			fi
		;;
		* ) 
			echo "ERROR: Invalid argument: \""$opt"\"" >&2
                	exit 1;;
		esac
	done
fi

if [[ "$genome_build" == "" ]]; then
                            echo -ne "Genome build not specified.Using hg19.\n" >&2;
				genome_build="snp147_hg19";
                        fi


 if [[ "$in_list" == "" ]]; then
                            echo -ne "ERROR: input file is mandatory. \n" >&2
                            exit 1
                        fi

if [[ "$out_file" == "" ]]; then
                                out_file="/dev/stdout";
                                echo -ne "Output file not specified. Printing output to stdout\n" >&2
                        fi

echo -ne "Using dbSNP version 147.. \n";

echo -ne "Here are your input options:\ngenome:\t$genome_build\ninput file:\t$in_list\noutput file=\t$out_file\nscript to call=$tocall\n";

if [[ $opt == "get-nearby-genes" ]]
then
	$tocall -i $in_list -o $out_file -g $genome_build -w $window;
else
	$tocall -i $in_list -o $out_file -g $genome_build;
fi
