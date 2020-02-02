# -*-makefile-*-
#
# train Opus-MT models using MarianNMT
#
#--------------------------------------------------------------------
#
# (1) train NMT model
#
# make train .............. train NMT model for current language pair
#
# (2) translate and evaluate
#
# make translate .......... translate test set
# make eval ............... evaluate
#
#--------------------------------------------------------------------
#
#   Makefile.tasks ...... various common and specific tasks/experiments
#   Makefile.generic .... generic targets (in form of prefixes to be added to other targets)
#
# Examples from Makefile.tasks:
#
# * submit job to train a model in one specific translation direction
#   (make data on CPU and then start a job on a GPU node with 4 GPUs)
#   make SRCLANGS=en TRGLANGS=de unidrectional.submitcpu
#
# * submit jobs to train a model in both translation directions
#   (make data on CPU, reverse data and start 2 jobs on a GPU nodes with 4 GPUs each)
#   make SRCLANGS=en TRGLANGS=de bilingual.submitcpu
#
# * same as bilingual but guess some HPC settings based on data size
#   make SRCLANGS=en TRGLANGS=de bilingual-dynamic.submitcpu
#
# * submit jobs for all OPUS languages to PIVOT language in both directions using bilingual-dynamic
#   make PIVOT=en allopus2pivot              # run loop on command line
#   make PIVOT=en allopus2pivot.submitcpu    # submit the same as CPU-based job
#   make all2en.submitcpu                    # short form of the same
#
# * submit jobs for all combinations of OPUS languages (this is huge!)
#   (only if there is no train.submit in the workdir of the language pair)
#   make PIVOT=en allopus.submitcpu
#
# * submit a job to train a multilingual model with the same languages on both sides
#   make LANGS="en de fr" multilingual.submitcpu
#
#--------------------------------------------------------------------
# Some examples using generic extensions
#
# * submit job to train en-ru with backtranslation data from backtranslate/
#   make HPC_CORES=4 WALLTIME=24 SRCLANGS=en TRGLANGS=ru unidirectional-add-backtranslations.submitcpu
#
# * submit job that evaluates all currently trained models:
#   make eval-allmodels.submit
#   make eval-allbilingual.submit   # only bilingual models
#   make eval-allbilingual.submit   # only multilingual models
#
#--------------------------------------------------------------------
#
# general parameters / variables (see Makefile.config)
#   SRCLANGS ............ set source language(s)      (en)
#   TRGLANGS ............ set target language(s)      (de)
#
# 
# submit jobs by adding suffix to make-target to be run
#   .submit ........ job on GPU nodes (for train and translate)
#   .submitcpu ..... job on CPU nodes (for translate and eval)
#
# for example:
#    make train.submit
#
# run a multigpu job, for example
#    make train-multigpu.submit
#    make train-twogpu.submit
#    make train-gpu01.submit
#    make train-gpu23.submit
#
#
# typical procedure: train and evaluate en-de with 3 models in ensemble
#
# make data.submitcpu
# make vocab.submit
# make NR=1 train.submit
# make NR=2 train.submit
# make NR=3 train.submit
#
# make NR=1 eval.submit
# make NR=2 eval.submit
# make NR=3 eval.submit
# make eval-ensemble.submit
#
#
# include right-to-left models:
#
# make NR=1 train-RL.submit
# make NR=2 train-RL.submit
# make NR=3 train-RL.submit
#
#
#--------------------------------------------------------------------
# train several versions of the same model (for ensembling)
#
#   make NR=1 ....
#   make NR=2 ....
#   make NR=3 ....
#
# DANGER: problem with vocabulary files if you start them simultaneously
#         --> racing situation for creating them between the processes
#
#--------------------------------------------------------------------
# resume training
#
#   make resume
#
#--------------------------------------------------------------------
# translate with ensembles of models
#
#   make translate-ensemble
#   make eval-ensemble
#
# this only makes sense if there are several models
# (created with different NR)
#--------------------------------------------------------------------


# check and adjust Makfile.env and Makfile.config
# add specific tasks in Makefile.tasks

SHELL := /bin/bash

include Makefile.env
include Makefile.config
include Makefile.dist
include Makefile.tasks
include Makefile.data
include Makefile.doclevel
include Makefile.generic
include Makefile.slurm


#------------------------------------------------------------------------
# make various data sets
#------------------------------------------------------------------------


.PHONY: data
data:	${TRAIN_SRC}.clean.${PRE_SRC}.gz ${TRAIN_TRG}.clean.${PRE_TRG}.gz \
	${DEV_SRC}.${PRE_SRC} ${DEV_TRG}.${PRE_TRG}
	${MAKE} ${TEST_SRC}.${PRE_SRC} ${TEST_TRG}
	${MAKE} ${TRAIN_ALG}
	${MAKE} ${MODEL_VOCAB}


traindata: 	${TRAIN_SRC}.clean.${PRE_SRC}.gz ${TRAIN_TRG}.clean.${PRE_TRG}.gz
tunedata: 	${TUNE_SRC}.${PRE_SRC} ${TUNE_TRG}.${PRE_TRG}
devdata:	${DEV_SRC}.${PRE_SRC} ${DEV_TRG}.${PRE_TRG}
testdata:	${TEST_SRC}.${PRE_SRC} ${TEST_TRG}
wordalign:	${TRAIN_ALG}

devdata-raw:	${DEV_SRC} ${DEV_TRG}


#------------------------------------------------------------------------
# train, translate and evaluate
#------------------------------------------------------------------------


## other model types
vocab: ${MODEL_VOCAB}
train: ${WORKDIR}/${MODEL}.${MODELTYPE}.model${NR}.done
translate: ${WORKDIR}/${TESTSET}.${MODEL}${NR}.${MODELTYPE}.${SRC}.${TRG}
eval: ${WORKDIR}/${TESTSET}.${MODEL}${NR}.${MODELTYPE}.${SRC}.${TRG}.eval
compare: ${WORKDIR}/${TESTSET}.${MODEL}${NR}.${MODELTYPE}.${SRC}.${TRG}.compare

## ensemble of models (assumes to find them in subdirs of the WORKDIR)
translate-ensemble: ${WORKDIR}/${TESTSET}.${MODEL}${NR}.${MODELTYPE}.ensemble.${SRC}.${TRG}
eval-ensemble: ${WORKDIR}/${TESTSET}.${MODEL}${NR}.${MODELTYPE}.ensemble.${SRC}.${TRG}.eval


#------------------------------------------------------------------------
# translate and evaluate all test sets in testsets/
#------------------------------------------------------------------------

## testset dir for all test sets in this language pair
## and all trokenized test sets that can be found in that directory
TESTSET_HOME    = ${PWD}/testsets
TESTSET_DIR     = ${TESTSET_HOME}/${SRC}-${TRG}
TESTSETS        = $(sort $(patsubst ${TESTSET_DIR}/%.${SRC}.gz,%,${wildcard ${TESTSET_DIR}/*.${SRC}.gz}))
TESTSETS_PRESRC = $(patsubst %,${TESTSET_DIR}/%.${SRC}.${PRE}.gz,${TESTSETS})
TESTSETS_PRETRG = $(patsubst %,${TESTSET_DIR}/%.${TRG}.${PRE}.gz,${TESTSETS})

# TESTSETS_PRESRC = $(patsubst %.gz,%.${PRE}.gz,${sort $(subst .${PRE},,${wildcard ${TESTSET_DIR}/*.${SRC}.gz})})
# TESTSETS_PRETRG = $(patsubst %.gz,%.${PRE}.gz,${sort $(subst .${PRE},,${wildcard ${TESTSET_DIR}/*.${TRG}.gz})})

## eval all available test sets
eval-testsets:
	for s in ${SRCLANGS}; do \
	  for t in ${TRGLANGS}; do \
	    ${MAKE} SRC=$$s TRG=$$t compare-testsets-langpair; \
	  done \
	done

eval-heldout:
	${MAKE} TESTSET_HOME=${HELDOUT_DIR} eval-testsets

%-testsets-langpair: ${TESTSETS_PRESRC} ${TESTSETS_PRETRG}
	@echo "testsets: ${TESTSET_DIR}/*.${SRC}.gz"
	for t in ${TESTSETS}; do \
	  ${MAKE} TESTSET=$$t ${@:-testsets-langpair=}; \
	done



#------------------------------------------------------------------------
# some helper functions
#------------------------------------------------------------------------


## check whether a model is converged or not
finished:
	@if grep -q 'stalled ${MARIAN_EARLY_STOPPING} times' ${WORKDIR}/${MODEL_VALIDLOG}; then\
	   echo "${WORKDIR}/${MODEL_BASENAME} finished"; \
	else \
	   echo "${WORKDIR}/${MODEL_BASENAME} unfinished"; \
	fi

## remove job files if no trained file exists
delete-broken-submit:
	for l in ${ALL_LANG_PAIRS}; do \
	  if [ -e ${WORKHOME}/$$l/train.submit ]; then \
	    if  [ ! `find ${WORKHOME}/$$l -name '*.${PRE_SRC}-${PRE_TRG}.*.best-perplexity.npz' | wc -l` -gt 0 ]; then \
	      echo "rm -f ${WORKHOME}/$$l/train.submit"; \
	      rm -f ${WORKHOME}/$$l/train.submit; \
	    fi \
	  fi \
	done


## resume training on an existing model
resume:
	if [ -e ${WORKDIR}/${MODEL}.${MODELTYPE}.model${NR}.npz.best-perplexity.npz ]; then \
	  cp ${WORKDIR}/${MODEL}.${MODELTYPE}.model${NR}.npz.best-perplexity.npz \
	     ${WORKDIR}/${MODEL}.${MODELTYPE}.model${NR}.npz; \
	fi
	sleep 1
	rm -f ${WORKDIR}/${MODEL}.${MODELTYPE}.model${NR}.done
	${MAKE} train





#------------------------------------------------------------------------
# training MarianNMT models
#------------------------------------------------------------------------


## make vocabulary
## - no new vocabulary is created if the file already exists!
## - need to delete the file if you want to create a new one!

${MODEL_VOCAB}:	${TRAIN_SRC}.clean.${PRE_SRC}${TRAINSIZE}.gz \
		${TRAIN_TRG}.clean.${PRE_TRG}${TRAINSIZE}.gz
ifeq ($(wildcard ${MODEL_VOCAB}),)
	mkdir -p ${dir $@}
	${LOADMODS} && zcat $^ | ${MARIAN}/marian-vocab --max-size ${VOCABSIZE} > $@
else
	@echo "$@ already exists!"
	@echo "WARNING! No new vocabulary is created even though the data has changed!"
	@echo "WARNING! Delete the file if you want to start from scratch!"
	touch $@
endif


## NEW: take away dependency on ${MODEL_VOCAB}
## (will be created by marian if it does not exist)

## train transformer model
${WORKDIR}/${MODEL}.transformer.model${NR}.done: \
		${TRAIN_SRC}.clean.${PRE_SRC}${TRAINSIZE}.gz \
		${TRAIN_TRG}.clean.${PRE_TRG}${TRAINSIZE}.gz \
		${DEV_SRC}.${PRE_SRC} ${DEV_TRG}.${PRE_TRG}
	mkdir -p ${dir $@}
	${LOADMODS} && ${MARIAN}/marian ${MARIAN_EXTRA} \
        --model $(@:.done=.npz) \
	--type transformer \
        --train-sets ${word 1,$^} ${word 2,$^} ${MARIAN_TRAIN_WEIGHTS} \
        --max-length 500 \
        --vocabs ${MODEL_VOCAB} ${MODEL_VOCAB} \
        --mini-batch-fit \
	-w ${MARIAN_WORKSPACE} \
	--maxi-batch ${MARIAN_MAXI_BATCH} \
        --early-stopping ${MARIAN_EARLY_STOPPING} \
        --valid-freq ${MARIAN_VALID_FREQ} \
	--save-freq ${MARIAN_SAVE_FREQ} \
	--disp-freq ${MARIAN_DISP_FREQ} \
        --valid-sets ${word 3,$^} ${word 4,$^} \
        --valid-metrics perplexity \
        --valid-mini-batch ${MARIAN_VALID_MINI_BATCH} \
        --beam-size 12 --normalize 1 --allow-unk \
        --log $(@:.model${NR}.done=.train${NR}.log) \
	--valid-log $(@:.model${NR}.done=.valid${NR}.log) \
        --enc-depth 6 --dec-depth 6 \
        --transformer-heads 8 \
        --transformer-postprocess-emb d \
        --transformer-postprocess dan \
        --transformer-dropout ${MARIAN_DROPOUT} \
	--label-smoothing 0.1 \
        --learn-rate 0.0003 --lr-warmup 16000 --lr-decay-inv-sqrt 16000 --lr-report \
        --optimizer-params 0.9 0.98 1e-09 --clip-norm 5 \
        --tied-embeddings-all \
	--overwrite --keep-best \
	--devices ${MARIAN_GPUS} \
        --sync-sgd --seed ${SEED} \
	--sqlite \
	--tempdir ${TMPDIR} \
        --exponential-smoothing
	touch $@







## NEW: take away dependency on ${MODEL_VOCAB}

## train transformer model with guided alignment
${WORKDIR}/${MODEL}.transformer-align.model${NR}.done: \
		${TRAIN_SRC}.clean.${PRE_SRC}${TRAINSIZE}.gz \
		${TRAIN_TRG}.clean.${PRE_TRG}${TRAINSIZE}.gz \
		${TRAIN_ALG} \
		${DEV_SRC}.${PRE_SRC} ${DEV_TRG}.${PRE_TRG}
	mkdir -p ${dir $@}
	${LOADMODS} && ${MARIAN}/marian ${MARIAN_EXTRA} \
        --model $(@:.done=.npz) \
	--type transformer \
        --train-sets ${word 1,$^} ${word 2,$^} ${MARIAN_TRAIN_WEIGHTS} \
        --max-length 500 \
        --vocabs ${MODEL_VOCAB} ${MODEL_VOCAB} \
        --mini-batch-fit \
	-w ${MARIAN_WORKSPACE} \
	--maxi-batch ${MARIAN_MAXI_BATCH} \
        --early-stopping ${MARIAN_EARLY_STOPPING} \
        --valid-freq ${MARIAN_VALID_FREQ} \
	--save-freq ${MARIAN_SAVE_FREQ} \
	--disp-freq ${MARIAN_DISP_FREQ} \
        --valid-sets ${word 4,$^} ${word 5,$^} \
        --valid-metrics perplexity \
        --valid-mini-batch ${MARIAN_VALID_MINI_BATCH} \
        --beam-size 12 --normalize 1 --allow-unk \
        --log $(@:.model${NR}.done=.train${NR}.log) \
	--valid-log $(@:.model${NR}.done=.valid${NR}.log) \
        --enc-depth 6 --dec-depth 6 \
        --transformer-heads 8 \
        --transformer-postprocess-emb d \
        --transformer-postprocess dan \
        --transformer-dropout ${MARIAN_DROPOUT} \
	--label-smoothing 0.1 \
        --learn-rate 0.0003 --lr-warmup 16000 --lr-decay-inv-sqrt 16000 --lr-report \
        --optimizer-params 0.9 0.98 1e-09 --clip-norm 5 \
        --tied-embeddings-all \
	--overwrite --keep-best \
	--devices ${MARIAN_GPUS} \
        --sync-sgd --seed ${SEED} \
	--sqlite \
	--tempdir ${TMPDIR} \
        --exponential-smoothing \
	--guided-alignment ${word 3,$^}
	touch $@



#------------------------------------------------------------------------
# translate with an ensemble of several models
#------------------------------------------------------------------------

ENSEMBLE = ${wildcard ${WORKDIR}/${MODEL}.${MODELTYPE}.model*.npz.best-perplexity.npz}

${WORKDIR}/${TESTSET}.${MODEL}${NR}.${MODELTYPE}.ensemble.${SRC}.${TRG}: ${TEST_SRC}.${PRE_SRC} ${ENSEMBLE}
	mkdir -p ${dir $@}
	grep . $< > $@.input
	${LOADMODS} && ${MARIAN}/marian-decoder -i $@.input \
		--models ${ENSEMBLE} \
		--vocabs ${WORKDIR}/${MODEL}.vocab.yml \
			${WORKDIR}/${MODEL}.vocab.yml \
			${WORKDIR}/${MODEL}.vocab.yml \
		${MARIAN_DECODER_FLAGS} > $@.output
ifeq (${PRE_TRG},spm${TRGBPESIZE:000=}k)
	sed 's/ //g;s/▁/ /g' < $@.output | sed 's/^ *//;s/ *$$//' > $@
else
	sed 's/\@\@ //g;s/ \@\@//g;s/ \@\-\@ /-/g' < $@.output |\
	$(TOKENIZER)/detokenizer.perl -l ${TRG} > $@
endif
	rm -f $@.input $@.output


#------------------------------------------------------------------------
# translate, evaluate and generate a file 
# for comparing system to reference translations
#------------------------------------------------------------------------

${WORKDIR}/${TESTSET}.${MODEL}${NR}.${MODELTYPE}.${SRC}.${TRG}: ${TEST_SRC}.${PRE_SRC} ${MODEL_FINAL}
	mkdir -p ${dir $@}
	grep . $< > $@.input
	${LOADMODS} && ${MARIAN}/marian-decoder -i $@.input \
		-c ${word 2,$^}.decoder.yml \
		-d ${MARIAN_GPUS} \
		${MARIAN_DECODER_FLAGS} > $@.output
ifeq (${PRE_TRG},spm${TRGBPESIZE:000=}k)
	sed 's/ //g;s/▁/ /g' < $@.output | sed 's/^ *//;s/ *$$//' > $@
else
	sed 's/\@\@ //g;s/ \@\@//g;s/ \@\-\@ /-/g' < $@.output |\
	$(TOKENIZER)/detokenizer.perl -l ${TRG} > $@
endif
	rm -f $@.input $@.output



%.eval: % ${TEST_TRG}
	paste ${TEST_SRC}.${PRE_SRC} ${TEST_TRG} | grep $$'.\t' | cut -f2 > $@.ref
	cat $< | sacrebleu $@.ref > $@
	cat $< | sacrebleu --metrics=chrf --width=3 $@.ref >> $@
	rm -f $@.ref


%.compare: %.eval
	grep . ${TEST_SRC} > $@.1
	grep . ${TEST_TRG} > $@.2
	grep . ${<:.eval=} > $@.3
	paste -d "\n" $@.1 $@.2 $@.3 |\
	sed 	-e "s/&apos;/'/g" \
		-e 's/&quot;/"/g' \
		-e 's/&lt;/</g' \
		-e 's/&gt;/>/g' \
		-e 's/&amp;/&/g' |\
	sed 'n;n;G;' > $@
	rm -f $@.1 $@.2 $@.3
