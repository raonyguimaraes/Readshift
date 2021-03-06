#!/bin/bash
# shift_quality 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    echo "Value of reads: '${reads[@]}'"
    echo "Value of mates: '${mates[@]}'"
    echo "Value of desired_coverage: '$downsample_fraction'"
    echo "Value of standard_deviation_shift: '$standard_deviation_shift'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    set -x

    reads_name=$(dx describe "$reads" --name)
    mates_name=$(dx describe "$mates" --name)

    reads_name=${reads_name%.fastq.gz}
    reads_name=${reads_name%fq.gz}
    reads_name=${reads_name}.requal.fastq.gz

    mates_name=${mates_name%.fastq.gz}
    mates_name=${mates_name%fq.gz}
    mates_name=${mates_name}.requal.fastq.gz

    dx download "$reads" -o - | zcat > reads.fastq &
    dx download "$mates" -o - | zcat > mates.fastq &

    wait

    mkfifo output.1.fastq
    mkfifo output.2.fastq

    python /shift_quality.py --reads reads.fastq --mates mates.fastq --output-reads output.1.fastq  --output-mates output.2.fastq  --downsample-fraction $downsample_fraction --starting-mean $starting_mean --starting-stdev $starting_stdev --stdev-shift $standard_deviation_shift &

    cat output.1.fastq | gzip -c > output.1.fastq.gz &
    cat output.2.fastq | gzip -c > output.2.fastq.gz

    wait

    output_reads=$(dx upload output.1.fastq.gz -o $reads_name --brief)
    output_mates=$(dx upload output.2.fastq.gz -o $mates_name --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output output_reads "$output_reads" --class=file
    dx-jobutil-add-output output_mates "$output_mates" --class=file
}
