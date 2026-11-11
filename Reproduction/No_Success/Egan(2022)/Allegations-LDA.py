
# coding: utf-8

# In[23]:


import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.feature_extraction import text
from sklearn.decomposition import NMF, LatentDirichletAllocation
from nltk.stem import WordNetLemmatizer, PorterStemmer
import nltk
import string
from nltk.tokenize import sent_tokenize
import os
# Import Wordnet if needed
#nltk.download('wordnet')

###################################################
########## Inputs
###################################################

stem_name = ['Porter','Lemma']
cd = str(os.getcwd()) #Working directory,location of file
filename = 'allegations_and_charges.csv'
col_name = 'alleg_or_charge' #Name of column with text documents
no_topics = 10
stop_word_list = ['fired','terminated','laid off','let go','discharged','termination','employment','resignation','resigned','suspended','suspension','resign'] #Custom Stop Words
no_features = 1000

def stem_tokens(tokens, stemmer):
	stemmed = []
	for item in tokens:
		try:
			stemmed.append(stemmer.lemmatize(item))
		except:
			stemmed.append(stemmer.stem(item))
	return stemmed

def tokenize(text):
	tokens = []
	sent_text = sent_tokenize(text)
	for u in range(0,len(sent_text)):
		tokens = tokens + nltk.word_tokenize(sent_text[u])
	stems = stem_tokens(tokens, stemmer)
	return stems

def read_file(cd,filename,col_name):
	file = pd.read_csv(str(cd) + '/' + str(filename),dtype={str(col_name):str})
	file = file[(file[str(col_name)].notnull())].drop_duplicates(subset=str(col_name)).reset_index(drop=True)
	docs = file[str(col_name)].values
	token_dict = {}
	for x in range(0,len(docs)):
		lowers = docs[x]
		no_punctuation = lowers.translate(string.punctuation)
		token_dict[docs[x]] = no_punctuation
	return file, token_dict

def bag_of_words_function(no_features,my_stop_words,token_dict,col_name):
	tf_vectorizer = CountVectorizer(tokenizer=tokenize,max_df=0.95, min_df=2, max_features=no_features, stop_words=my_stop_words)
	tf = tf_vectorizer.fit_transform(token_dict.values())
	tf_feature_names = list(tf_vectorizer.get_feature_names())
	bag_of_words = pd.DataFrame(tf.toarray(),columns=list(tf_feature_names))
	bag_of_words[str(col_name)] = pd.DataFrame(list(token_dict.values()))
	return bag_of_words



for w in range(0,2):
	if w==0:
		stemmer = PorterStemmer()
	else:
		stemmer = WordNetLemmatizer()
	file,token_dict = read_file(cd,filename,col_name)
	stop_word_list_caps = [x.upper() for x in stop_word_list]
	stop_word_list = stop_word_list + stop_word_list_caps
	############################# To Omit NLTK tokenization, remove tokenizer=tokenize args ######
	my_stop_words = text.ENGLISH_STOP_WORDS.union(stop_word_list)
	print('TFIDF Processing')
	tfidf_vectorizer = TfidfVectorizer(tokenizer=tokenize,max_df=0.95, min_df=2, max_features=no_features, stop_words=my_stop_words)
	tfidf = tfidf_vectorizer.fit_transform(token_dict.values())
	tfidf_feature_names = tfidf_vectorizer.get_feature_names()
	# bag_of_words = bag_of_words_function(no_features,my_stop_words,token_dict,col_name)
	# bag_of_words.to_csv(str(cd) + '/Bag_of_Words_' + str(stem_name[w]) + '.csv',sep='|',index=False)
	###################################
	####### LDA Model ##############
	###################################
	print('LDA Processing')
	lda = LatentDirichletAllocation(n_components=no_topics,random_state=0).fit(tfidf)
	ldadf = pd.DataFrame(lda.transform(tfidf))
	ldadf[str(col_name)] = pd.DataFrame(list(token_dict.values()))
	top_category = []
	max_prob = []
	print('Creating DataFrame')
	lda_vals = ldadf.iloc[:,:int(no_topics)].values
	for x in range(0,len(ldadf)):
		top_category.append(np.nanargmax(lda_vals[x]))
		max_prob.append(np.amax(lda_vals[x]))
	ldadf['Top_Category'] = pd.DataFrame(top_category)
	ldadf['Prob'] = pd.DataFrame(max_prob)
	del file
	ldadf.to_csv(str(cd) + '/LDA_Allegations+' + str(stem_name[w]) + '_LDA_u.txt',sep='|',index=False)
	print('Completed')
