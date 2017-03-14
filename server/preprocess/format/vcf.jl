using OhMyJulia

parse_int_add(x::AbstractString,y::AbstractString) = parse(Int, x) + parse(Int, y)
parse_int_add(x::Integer,y::AbstractString) = x + parse(Int, y)

first_else(f, list, alt) = (i = findfirst(f, list)) == 0 ? alt : list[i]

const transcript_of_intrest = Dict(split(x, '\t')[1:2] for x in eachline(project"../data/Gene_transcript.list"))

function parse_vcf(file)
    null = "."
    is_pair = eachline(file) ~ :drop(1) ~ :take(1) ~ collect ~ car ~ :split('\t') ~ length ~ isequal(63)
    sequencing_strategy = is_pair ? "pair" : "single"

    for line in drop(eachline(file), 1)
        line = split(line, '\t')

        chr, position, ref, alt = line[[1,2,4,5]]

        dbsnp = line[18]

        gene = line[7] ~ :split(r"[,;]") ~ car

        func = try
            match(r"ncRNA|exonic|intronic|splicing|UTR3|UTR5|upstream|downstream|intergenic", line[6]).match
        catch
            "unknown"
        end

        transcript, region, nucleotide, protein = ntuple(x->null, 4)

        if line[10] != null && line[10] != "UNKNOWN"
            candidates = map(x->split(x, ':'), split(line[10], r"[,;]"))
            i = findfirst(x->cadr(x) == get(transcript_of_intrest, gene, "fuck"), candidates)
            if i != 0
                if length(candidates[i]) == 5
                    gene, transcript, region, nucleotide, protein = candidates[i]
                elseif length(candidates[i]) == 3
                    gene, transcript, region = candidates[i]
                else
                    println(STDERR, file)
                    println(STDERR, line[10])
                end
            end
        elseif contains(line[8], "NM_") || contains(line[8], "NR_")
            candidates = map(x->split(x, ':'), split(line[8], r"[,;]"))
            i = findfirst(x->car(x) == get(transcript_of_intrest, gene, "fuck"), candidates)
            if i != 0
                if length(candidates[i]) == 3
                    transcript, region, nucleotide = candidates[i]
                elseif length(candidates[i]) == 2
                    transcript, nucleotide = candidates[i]
                else
                    println(STDERR, file)
                    println(STDERR, line[8])
                end
            end
        end

        sift = line[19] == null ? "-1" : line[19]

        clinvar = line[45]

        if line[44] == null
            cosmic_id, cosmic_occu = null, 0
        else
            cosmic_id, cosmic_occu = match(r"ID=(.*);OCCURENCE=(.*)$", line[44]).captures
            try
                cosmic_occu = reduce(parse_int_add, 0, split(replace(cosmic_occu, r"[^\d,]", ""), ','))
            catch
                println(STDERR, cosmic_occu)
            end
        end

        @assert length(line) == (is_pair ? 63 : 62)

        tumor = split(line[end][1:end-1], ':')

        kgenome_af = line[14] == null ? "0" : line[14]

        mrbam = split(tumor[end], ',')

        multiple_overlap_ref, multiple_nonoverlap_ref, multiple_single_ref = mrbam[1],  mrbam[2], mrbam[3]
        one_overlap_ref,      one_nonoverlap_ref,      one_single_ref      = mrbam[4],  mrbam[5], mrbam[6]
        multiple_overlap_alt, multiple_nonoverlap_alt, multiple_single_alt = mrbam[7],  mrbam[8], mrbam[9]
        one_overlap_alt,      one_nonoverlap_alt,      one_single_alt      = mrbam[10], mrbam[11], mrbam[12]

        unique_ref, unique_alt = reduce(parse_int_add, mrbam[1:6]), reduce(parse_int_add, mrbam[7:12])
        unique_total = unique_ref + unique_alt
        unique_af    = unique_alt / unique_total

        unique_alt < 2 && continue

        if is_pair
            normal = split(line[end-1], ':')

            tumor_depth = tumor[3]
            tumor_af, tumor_altread   = string(tumor[6][1:end-1], "E-2"), tumor[5]
            normal_af, normal_altread = string(normal[6][1:end-1], "E-2"), normal[5]

            ref_forward_strand, ref_reverse_strand, alt_forward_strand, alt_reverse_strand = split(tumor[end-1], ',')

            ssc, gpv, spv = match(r"SSC=(.*);GPV=(.*);SPV=(.*)", line[60]).captures
            abq, rbq = "-1", "-1"
        else
            tumor_depth = tumor[4]
            tumor_af, tumor_altread = string(tumor[7][1:end-1], "E-2"), tumor[6]
            ref_forward_strand, ref_reverse_strand, alt_forward_strand, alt_reverse_strand = tumor[end-4:end-1]
            gpv, rbq, abq = tumor[[8,9,10]]
            spv, ssc, normal_af, normal_altread = ntuple(x->"-1", 4)
        end

        prt(mut, sequencing_strategy, chr, position, ref, alt,
            dbsnp, gene, transcript, func, region, nucleotide, protein,
            sift, clinvar, cosmic_id, cosmic_occu, kgenome_af, tumor_af, tumor_altread,
            multiple_overlap_ref, multiple_nonoverlap_ref, multiple_single_ref,
            one_overlap_ref, one_nonoverlap_ref, one_single_ref,
            multiple_overlap_alt, multiple_nonoverlap_alt, multiple_single_alt,
            one_overlap_alt, one_nonoverlap_alt, one_single_alt,
            unique_total, unique_alt, unique_af, tumor_depth,
            ref_forward_strand, ref_reverse_strand, alt_forward_strand, alt_reverse_strand,
            gpv, spv, ssc, normal_af, normal_altread, rbq, abq)
    end
end


