#
# fine-tune an existing model
# set SRC and TRG to source and target language IDs
# defaults: SRC=en TRG=de
#
#  make SRC=xx TRG=yy news-tune-data ...... create tuning data from newstest sets
#  make SRC=xx TRG=yy all ................. tune and eval
#
# other targets:
#
#  make news-enfi ......... make tuned model for en-fi News
#  make goethe-defi ....... make model for Goethe Institute data
#  make data .............. pre-process train/dev data
#  make tune .............. fine-tune model
#  make translate ......... translate test set with fine-tuned model
#  make translate-baseline  translate test set with baseline model
#  make eval .............. evaluate test set translation (fine-tuned)
#  make eval-baseline ..... evaluate test set translation (baseline)
#  make compare ........... put together source, reference translation and system output
#  make compare-baseline .. same as compare but with baseline translation
#
#
# NOTE: all this only works for SentencePiece models
#
# TODO
# - download base models from ObjectStorage
# - make it work with multilingual models
#   --> need to adjust preprocess-scripts for those models
#

include ../Makefile.env
include ../Makefile.config
include ../Makefile.slurm


SRC       = en
TRG       = de
LANGPAIR  = ${SRC}-${TRG}
MODEL     = news

TRAIN_SRC = ${patsubst %.gz,%,$(wildcard ${LANGPAIR}/${MODEL}/train/*.${SRC}.gz)}
DEV_SRC   = ${patsubst %.gz,%,$(wildcard ${LANGPAIR}/${MODEL}/dev/*.${SRC}.gz)}
TEST_SRC  = ${patsubst %.gz,%,$(wildcard ${LANGPAIR}/${MODEL}/test/*.${SRC}.gz)}

TRAIN_TRG = ${patsubst %.${SRC},%.${TRG},${TRAIN_SRC}}
DEV_TRG   = ${patsubst %.${SRC},%.${TRG},${DEV_SRC}}
TEST_TRG  = ${patsubst %.${SRC},%.${TRG},${TEST_SRC}}


BASEMODELHOME     = ../models/${LANGPAIR}
BASEMODELZIP      = ${lastword ${sort ${wildcard ${BASEMODELHOME}/*-20*.zip}}}
BASEMODELNAME     = ${patsubst %.zip,%,${notdir ${BASEMODELZIP}}}


TUNED_MODEL       = ${LANGPAIR}/${MODEL}/model/${BASEMODELNAME}_${MODEL}.transformer.model
TUNED_MODEL_VOCAB = ${LANGPAIR}/${MODEL}/model/${BASEMODELNAME}_${MODEL}.vocab.yml


MARIAN_WORKSPACE       = 5000
MARIAN_VALID_FREQ     = 100
MARIAN_SAVE_FREQ      = ${MARIAN_VALID_FREQ}
MARIAN_DISP_FREQ      = ${MARIAN_VALID_FREQ}
MARIAN_EARLY_STOPPING = 5




.PHONY: all
all: ${TEST_SRC}.${TRG}.compare ${TEST_SRC}.baseline.${TRG}.compare


.PHONY: news-enfi
news-enfi:
	${MAKE} SRC=en TRG=fi MODEL=news \
		TRAIN_SRC=en-fi/news/train/newstest2015-2018.en \
		TRAIN_TRG=en-fi/news/train/newstest2015-2018.fi \
		DEV_SRC=en-fi/news/dev/newsdev2015-enfi.en \
		DEV_TRG=en-fi/news/dev/newsdev2015-enfi.fi \
		TEST_SRC=en-fi/news/test/newstest2019-enfi.en \
		TEST_TRG=en-fi/news/test/newstest2019-enfi.fi \
	all

.PHONY: goethe-defi
goethe-defi:
	${MAKE} SRC=de TRG=fi MODEL=goethe \
		TRAIN_SRC=de-fi/goethe/train/goethe-institute-train.de \
		TRAIN_TRG=de-fi/goethe/train/goethe-institute-train.fi \
		DEV_SRC=de-fi/goethe/dev/goethe-institute-dev1.de \
		DEV_TRG=de-fi/goethe/dev/goethe-institute-dev1.fi \
		TEST_SRC=de-fi/goethe/test/goethe-institute-test1.de \
		TEST_TRG=de-fi/goethe/test/goethe-institute-test1.fi \
	all

goethe2-defi:
	${MAKE} SRC=de TRG=fi MODEL=goethe2 \
		TRAIN_SRC=de-fi/goethe/train/goethe-institute-train2.de \
		TRAIN_TRG=de-fi/goethe/train/goethe-institute-train2.fi \
		DEV_SRC=de-fi/goethe/dev/goethe-institute-dev2.de \
		DEV_TRG=de-fi/goethe/dev/goethe-institute-dev2.fi \
		TEST_SRC=de-fi/goethe/test/goethe-institute-test1.de \
		TEST_TRG=de-fi/goethe/test/goethe-institute-test1.fi \
	all


## without reference normalisation
goethe-other:
	zcat de-fi/goethe/test/goethe-institute-test1.fi.gz > $@.ref
	for s in systran yandex google; do \
	  cat ${HOME}/research/GoetheInstitute/data/test_de_oaversetted_van_$$s.txt |\
	   gzip -c > de-fi/goethe/test/goethe-institute-test1.de.$$s.de.gz; \
	  zcat de-fi/goethe/test/goethe-institute-test1.de.$$s.de.gz | sacrebleu $@.ref \
	  > de-fi/goethe/test/goethe-institute-test1.de.$$s.de.eval; \
	  zcat de-fi/goethe/test/goethe-institute-test1.de.$$s.de.gz | sacrebleu --metrics=chrf --width=3 $@.ref \
	  >> de-fi/goethe/test/goethe-institute-test1.de.$$s.de.eval; \
	done
	rm -f $@.ref

## with reference normalisation (should not do this)
goethe-other-norm:
	zcat de-fi/goethe/test/goethe-institute-test1.fi.gz |\
	${TOKENIZER}/replace-unicode-punctuation.perl |\
	${TOKENIZER}/remove-non-printing-char.perl |\
	${TOKENIZER}/normalize-punctuation.perl -l ${TRG} |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@.ref
	for s in systran yandex google; do \
	  cat ${HOME}/research/GoetheInstitute/data/test_de_oaversetted_van_$$s.txt |\
	  ${TOKENIZER}/replace-unicode-punctuation.perl |\
	  ${TOKENIZER}/remove-non-printing-char.perl |\
	  ${TOKENIZER}/normalize-punctuation.perl -l ${TRG} |\
	  sed 's/  */ /g;s/^ *//g;s/ *$$//g' | gzip -c > de-fi/goethe/test/goethe-institute-test1.de.$$s.de.gz; \
	  zcat de-fi/goethe/test/goethe-institute-test1.de.$$s.de.gz | sacrebleu $@.ref \
	  > de-fi/goethe/test/goethe-institute-test1.de.$$s.de.eval-norm; \
	  zcat de-fi/goethe/test/goethe-institute-test1.de.$$s.de.gz | sacrebleu --metrics=chrf --width=3 $@.ref \
	  >> de-fi/goethe/test/goethe-institute-test1.de.$$s.de.eval-norm; \
	done
	rm -f $@.ref

goethe-test:
	${MAKE} SRC=de TRG=fi MODEL=goethe-test \
		TRAIN_SRC=de-fi/goethe-test/train/goethe-all.de \
		TRAIN_TRG=de-fi/goethe-test/train/goethe-all.fi \
		DEV_SRC=de-fi/goethe-test/dev/goethe-institute-dev1.de \
		DEV_TRG=de-fi/goethe-test/dev/goethe-institute-dev1.fi \
		TEST_SRC=de-fi/goethe-test/test/goethe-institute-test1.de \
		TEST_TRG=de-fi/goethe-test/test/goethe-institute-test1.fi \
	all



## make news tuning data from testsets

TESTSETS_HOME     = ../testsets/${LANGPAIR}
NEWS_ALLSETS_SRC  = ${sort ${wildcard ${TESTSETS_HOME}/news*.${SRC}.gz}}
NEWS_ALLSETS_TRG  = ${sort ${wildcard ${TESTSETS_HOME}/news*.${TRG}.gz}}
NEWS_DEVSET_SRC   = ${firstword ${NEWS_ALLSETS_SRC}}
NEWS_DEVSET_TRG   = ${firstword ${NEWS_ALLSETS_TRG}}
NEWS_TESTSET_SRC  = ${lastword ${NEWS_ALLSETS_SRC}}
NEWS_TESTSET_TRG  = ${lastword ${NEWS_ALLSETS_TRG}}
NEWS_TRAINSET_SRC = ${filter-out ${NEWS_DEVSET_SRC} ${NEWS_TESTSET_SRC},${NEWS_ALLSETS_SRC}}
NEWS_TRAINSET_TRG = ${filter-out ${NEWS_DEVSET_TRG} ${NEWS_TESTSET_TRG},${NEWS_ALLSETS_TRG}}

.PHONY: news-tune-data
news-tune-data:
ifneq (${words ${NEWS_ALLSETS_SRC}},0)
ifneq (${words ${NEWS_ALLSETS_SRC}},1)
ifneq (${words ${NEWS_ALLSETS_SRC}},2)
	mkdir -p ${LANGPAIR}/news/train
	mkdir -p ${LANGPAIR}/news/dev
	mkdir -p ${LANGPAIR}/news/test
	cp ${NEWS_TESTSET_SRC} ${LANGPAIR}/news/test/
	cp ${NEWS_TESTSET_TRG} ${LANGPAIR}/news/test/
	cp ${NEWS_DEVSET_SRC} ${LANGPAIR}/news/dev/
	cp ${NEWS_DEVSET_TRG} ${LANGPAIR}/news/dev/
	zcat ${NEWS_TRAINSET_SRC} | gzip -c > ${LANGPAIR}/news/train/news.${SRC}.gz
	zcat ${NEWS_TRAINSET_TRG} | gzip -c > ${LANGPAIR}/news/train/news.${TRG}.gz
endif
endif
endif



.PHONY: data
data: ${TRAIN_SRC}.pre.gz ${TRAIN_TRG}.pre.gz ${DEV_SRC}.pre.gz ${DEV_TRG}.pre.gz

.INTERMEDIATE: ${LANGPAIR}/${BASEMODELNAME}/decoder.yml
${LANGPAIR}/${BASEMODELNAME}/decoder.yml:
	mkdir -p ${dir $@}
	cp ${BASEMODELZIP} ${dir $@}
	cd ${dir $@} && unzip -u *.zip

${TRAIN_SRC}.pre.gz ${DEV_SRC}.pre.gz ${TEST_SRC}.pre.gz: %.pre.gz: %.gz ${LANGPAIR}/${BASEMODELNAME}/decoder.yml
	zcat $< |\
	${LANGPAIR}/${BASEMODELNAME}/preprocess.sh ${SRC} ${LANGPAIR}/${BASEMODELNAME}/source.spm |\
	gzip -c > $@

${TRAIN_TRG}.pre.gz ${DEV_TRG}.pre.gz: %.pre.gz: %.gz ${LANGPAIR}/${BASEMODELNAME}/decoder.yml
	zcat $< |\
	${LANGPAIR}/${BASEMODELNAME}/preprocess.sh ${SRC} ${LANGPAIR}/${BASEMODELNAME}/target.spm |\
	gzip -c > $@




.PHONY: tune
tune: ${TUNED_MODEL}.done

## train transformer model
${TUNED_MODEL}.npz.best-perplexity.npz: ${TUNED_MODEL}.done

${TUNED_MODEL}.done: ${TRAIN_SRC}.pre.gz ${TRAIN_TRG}.pre.gz ${DEV_SRC}.pre.gz ${DEV_TRG}.pre.gz \
		${LANGPAIR}/${BASEMODELNAME}/decoder.yml
	mkdir -p ${dir $@}
	if [ ! -e ${@:done=npz} ]; then \
	  cp ${LANGPAIR}/${BASEMODELNAME}/*.npz ${@:done=npz}; \
	  cp ${LANGPAIR}/${BASEMODELNAME}/*.vocab.yml ${TUNED_MODEL_VOCAB}; \
	fi
	${LOADMODS} && ${MARIAN}/marian ${MARIAN_EXTRA} \
        --model $(@:.done=.npz) \
	--type transformer \
        --train-sets ${word 1,$^} ${word 2,$^} ${MARIAN_TRAIN_WEIGHTS} \
        --max-length 500 \
        --vocabs ${TUNED_MODEL_VOCAB} ${TUNED_MODEL_VOCAB} \
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
        --beam-size 12 --normalize 1 \
        --log $(@:.model.done=.train.log) --valid-log $(@:.model.done=.valid.log) \
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



.PHONY: translate
translate: ${TEST_SRC}.${TRG}.gz

## translate test set
${TEST_SRC}.${TRG}.gz: ${TEST_SRC}.pre.gz ${TUNED_MODEL}.npz.best-perplexity.npz
	mkdir -p ${dir $@}
	${LOADMODS} && ${MARIAN}/marian-decoder \
		-i $< \
		-c ${word 2,$^}.decoder.yml \
		-d ${MARIAN_GPUS} \
		${MARIAN_DECODER_FLAGS} |\
	sed 's/ //g;s/▁/ /g' | sed 's/^ *//;s/ *$$//' |\
	gzip -c > $@


.PHONY: translate-baseline
translate-baseline: ${TEST_SRC}.baseline.${TRG}.gz

## translate test set
${TEST_SRC}.baseline.${TRG}.gz: ${TEST_SRC}.pre.gz ${LANGPAIR}/${BASEMODELNAME}/decoder.yml
	mkdir -p ${dir $@}
	cd ${LANGPAIR}/${BASEMODELNAME}; \
	${LOADMODS} && ${MARIAN}/marian-decoder \
		-i ${PWD}/$< \
		-c decoder.yml \
		-d ${MARIAN_GPUS} \
		${MARIAN_DECODER_FLAGS} |\
	sed 's/ //g;s/▁/ /g' | sed 's/^ *//;s/ *$$//' |\
	gzip -c > ${PWD}/$@



.PHONY: eval eval-baseline
eval: ${TEST_SRC}.${TRG}.eval
eval-baseline: ${TEST_SRC}.baseline.${TRG}.eval

## without reference normalisation
${TEST_SRC}.${TRG}.eval ${TEST_SRC}.baseline.${TRG}.eval: %.eval: %.gz ${TEST_TRG}.gz
	zcat ${TEST_TRG}.gz > $@.ref
	zcat $< | sacrebleu $@.ref > $@
	zcat $< | sacrebleu --metrics=chrf --width=3 $@.ref >> $@
	rm -f $@.ref

## with reference normalisation (should not do this)
${TEST_SRC}.${TRG}.eval-norm ${TEST_SRC}.baseline.${TRG}.eval-norm: %.eval-norm: %.gz ${TEST_TRG}.gz
	zcat ${TEST_TRG}.gz |\
	${TOKENIZER}/replace-unicode-punctuation.perl |\
	${TOKENIZER}/remove-non-printing-char.perl |\
	${TOKENIZER}/normalize-punctuation.perl -l ${TRG} |\
	sed 's/  */ /g;s/^ *//g;s/ *$$//g' > $@.ref
	zcat $< | sacrebleu $@.ref > $@
	zcat $< | sacrebleu --metrics=chrf --width=3 $@.ref >> $@
	rm -f $@.ref




.PHONY: compare compare-baseline
compare: ${TEST_SRC}.${TRG}.compare
compare-baseline: ${TEST_SRC}.baseline.${TRG}.compare

${TEST_SRC}.${TRG}.compare ${TEST_SRC}.baseline.${TRG}.compare: %.compare: %.eval
	zcat ${TEST_SRC}.gz > $@.1
	zcat ${TEST_TRG}.gz > $@.2
	zcat ${<:.eval=.gz} > $@.3
	paste -d "\n" $@.1 $@.2 $@.3 |\
	sed 	-e "s/&apos;/'/g" \
		-e 's/&quot;/"/g' \
		-e 's/&lt;/</g' \
		-e 's/&gt;/>/g' \
		-e 's/&amp;/&/g' |\
	sed 'n;n;G;' > $@
	rm -f $@.1 $@.2 $@.3
