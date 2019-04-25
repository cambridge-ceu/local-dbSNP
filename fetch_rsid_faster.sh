#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=720
#SBATCH -n 1 
#SBATCH --job-name=fetch_rsIDs
#SBATCH --output=fetch_rsIDs.out
#SBATCH --error=fetch_rsIDs.err
#SBATCH --time=720          
#SBATCH --cpus-per-task=8
#SBATCH --partition=short

. /etc/profile.d/modules.sh      
module load default-cardio       
module load slurm
module load use.own

#mysql log in parameters
user="sk752";

###########################################################################
# given a list of variants in the format:
# chr1	1234
# this script fetches the corresponding rsIDs
# by querying the local dbSNP table.
# call the script like this:
# fetch_rsIDs.sh -i test_in.txt -o test_out txt -t snp147_hg19
###########################################################################
while getopts ":i:o:g" opt
   do
     case $opt in
        i ) in_list=$OPTARG;;
        o ) out_file=$OPTARG;;
	g ) genome_build=$OPTARG;;
      esac
done

date

if [[ $genome_build == "hg38" ]]
then
	table="snp147_hg38"
else
	table="snp147_hg19"
fi

#input validation
maxCols=$(awk -v FS="\t" '{if( NF > max ) max = NF} END {print max}' ${in_list})
minCols=$(awk -v FS="\t" -v min=2 '{if( NF < min ) min = NF} END {print min}' ${in_list})

#echo "max $maxCols\tmin $minCols\n"
if [[ ($maxCols -ne 2) || ($minCols -ne 2) ]]
then 
	echo -ne "Please check that the input file is tab separated and has exactly two columns\n"
	exit 1;
else
	#check that 2nd col is numeric
	numericCols=$(awk -v FS="\t" -v flag="yes" '{if( $2 !~ /^[0-9]+$/ ) flag = "no"} END {print flag}' ${in_list})	
	if [[ $numericCols == "no" ]]
	then
		echo -ne "Please check that the input positions are numeric\n"
	        exit 1;

	else
		#check that 1st col has chr prefix
		hasPrefix=$(grep -v '#' ${in_list}|head|grep "chr")		
		if [[ $hasPrefix == "" ]]; then
			awk '{print "chr"$0}' ${in_list} > tmp;
			#in_list="tmp";
		fi
		
		split -d -a 4 -l 1000 tmp temp;
		echo -ne "fetching requested variants from ${table} ...\n";
		count=1;
		for file in temp*;
		do
			echo "DROP TEMPORARY TABLE IF EXISTS temp_query_table;"|mysql -h cardio-login1 -u sk752 dbSNP_b149;
			if [[ "$count" -eq 1 ]]
			then
				echo "CREATE TEMPORARY TABLE temp_query_table (chrom varchar(31) NOT NULL, bp int(10) unsigned NOT NULL, INDEX chrom_bp (chrom,bp));
                                LOAD DATA LOCAL INFILE '$file' INTO TABLE temp_query_table;
                                SELECT a.chrom, a.chromStart, a.chromEnd, a.name, a.refNCBI, a.refUCSC, a.observed FROM $table AS a JOIN temp_query_table as b ON (a.chrom=b.chrom AND a.chromEnd=b.bp);
	                  " | mysql -h cardio-login1 -u sk752 dbSNP_b149 > $out_file;

			else
			#load data infile or use mysqlimport
				echo "CREATE TEMPORARY TABLE temp_query_table (chrom varchar(31) NOT NULL, bp int(10) unsigned NOT NULL, INDEX chrom_bp (chrom,bp));
        			LOAD DATA LOCAL INFILE '$file' INTO TABLE temp_query_table;
			        SELECT a.chrom, a.chromStart, a.chromEnd, a.name, a.refNCBI, a.refUCSC, a.observed FROM $table AS a JOIN temp_query_table as b ON (a.chrom=b.chrom AND a.chromEnd=b.bp);
     		     	" | mysql -N -h cardio-login1 -u sk752 dbSNP_b149 >> $out_file;
			fi
			#echo -ne "$count\n";
			count=$((count+1))
		done
		echo -ne "done\n";
	fi
fi

if [ -f "tmp" ]
then
	rm tmp;
fi

rm temp*;

date
