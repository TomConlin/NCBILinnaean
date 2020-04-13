'''
    see:
        http://etetoolkit.org/docs/latest/index.html
        http://etetoolkit.org/docs/latest/tutorial/tutorial_ncbitaxonomy.html
 
   updates:  ~/.etetoolkit/taxa.sqlite

   enables:  http://etetoolkit.org/documentation/tools/

   
'''


from ete3 import NCBITaxa
ncbi = NCBITaxa()
ncbi.update_taxonomy_database()


