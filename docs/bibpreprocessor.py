"""This preprocessor replaces bibliography code in markdowncell
"""

#-----------------------------------------------------------------------------
# Copyright (c) 2017, Yao Zheng
#
# Distributed under the terms of the Modified BSD License.
#
#-----------------------------------------------------------------------------

from nbconvert.preprocessors import *
import re
import os
import sys
import unicodedata

accents = {
    0x0300: '`', 0x0301: "'", 0x0302: '^', 0x0308: '"',
    0x030B: 'H', 0x0303: '~', 0x0327: 'c', 0x0328: 'k',
    0x0304: '=', 0x0331: 'b', 0x0307: '.', 0x0323: 'd',
    0x030A: 'r', 0x0306: 'u', 0x030C: 'v',
}

def uni2tex(text):
    out = ""
    txt = tuple(text)
    i = 0
    while i < len(txt):
        char = text[i]
        code = ord(char)

        # combining marks
        if unicodedata.category(char) in ("Mn", "Mc") and code in accents:
            out += "\\%s{%s}" %(accents[code], txt[i+1])
            i += 1
        # precomposed characters
        elif unicodedata.decomposition(char):
            base, acc = unicodedata.decomposition(char).split()
            acc = int(acc, 16)
            base = int(base, 16)
            if acc in accents:
                out += "\\%s{%s}" %(accents[acc], unichr(base))
            else:
                out += char
        else:
            out += char

        i += 1

    return out

class BibTexPreprocessor(Preprocessor):

    def create_bibentry(self, refkey, reference):
        try:
            if (reference["type"] == "article-journal"):
                entry  = "@article{" + refkey + ",\n"
                entry += "  author = {"
                entry += " and ".join(map(lambda a: a["family"] + ", " + a["given"], reference["author"]))
                entry += "}, \n"
                if ("title" in reference):
                    entry += "  title = {" + reference["title"] + "}, \n"
                if ("issued" in reference):
                    if ("year" in reference["issued"]):
                        entry += "  year = {" + reference["issued"]["year"] + "}, \n"
                    elif ("raw" in reference["issued"]):
                        entry += "  year = {" + reference["issued"]["raw"] + "}, \n"
                if ("container-title" in reference):
                    entry += "  journal = {" + reference["container-title"] + "}, \n"
                if ("page" in reference):
                    entry += "  pages = {" + re.sub("-", "--", reference["page"]) + "}, \n"
                if ("volume" in reference):
                    entry += "  volume = {" + reference["volume"] + "}, \n"
                if ("issue" in reference):
                    entry += "  issue = {" + reference["issue"] + "}, \n"
                if ("publisher" in reference):
                    entry += "  publisher = {" + reference["publisher"] + "}, \n"
                if ("DOI" in reference):
                    entry += "  doi = {" + reference["DOI"] + "}, \n"
                if ("URL" in reference):
                    entry += "  url = {" + reference["URL"] + "}, \n"
                entry += "}\n"
                entry += "\n"

            if (reference["type"] == "paper-conference"):
                entry  = "@conference{" + refkey + ",\n"
                entry += "  author = {"
                entry += " and ".join(map(lambda a: a["family"] + ", " + a["given"], reference["author"]))
                entry += "}, \n"
                if ("title" in reference):
                    entry += "  title = {" + reference["title"] + "}, \n"
                if ("issued" in reference):
                    if ("year" in reference["issued"]):
                        entry += "  year = {" + reference["issued"]["year"] + "}, \n"
                    elif ("raw" in reference["issued"]):
                        entry += "  year = {" + reference["issued"]["raw"] + "}, \n"
                if ("container-title" in reference):
                    entry += "  booktitle = {" + reference["container-title"] + "}, \n"
                elif ("event" in reference):
                    entry += "  booktitle = {" + reference["event"] + "}, \n"
                if ("page" in reference):
                    entry += "  pages = {" + re.sub("-", "--", reference["page"]) + "}, \n"
                if ("publisher" in reference):
                    entry += "  publisher = {" + reference["publisher"] + "}, \n"
                if ("URL" in reference):
                    entry += "  url = {" + reference["URL"] + "}, \n"
                entry += "}\n"
                entry += "\n"

            if (reference["type"] == "webpage"):
                entry  = "@misc{" + refkey + ",\n"
                if ("author" in reference):
                    entry += "  author = {"
                    entry += " and ".join(map(lambda a: a["family"] + ", " + a["given"], reference["author"]))
                    entry += "}, \n"
                if ("title" in reference):
                    entry += "  title = {" + reference["title"] + "}, \n"
                if ("URL" in reference):
                    entry += "  howpublished = {" + reference["URL"] + "}, \n"
                if ("access" in reference):
                    entry += "  note = {Accessd:" + reference["access"]["year"] + "-" \
                                                  + reference["access"]["month"] + "-" \
                                                  + reference["access"]["day"] + "}, \n"
                entry += "}\n"
                entry += "\n"

            entry = uni2tex(entry)
        except Exception as e:
            print reference
            print e

        return entry

    def create_bibfile(self, filename):
        if not os.path.exists(os.path.dirname(filename)):
            os.makedirs(os.path.dirname(filename))
        f = open(filename, "w")
        for r in self.references:
            if (sys.version_info > (3, 0)):
                f.write(self.create_bibentry(r, self.references[r]))
            else:
                f.write(self.create_bibentry(r, self.references[r]).encode('utf-8'))
        f.close()

    def preprocess(self, nb, resources):
        try:
          self.references = nb["metadata"]["cite2c"]["citations"]
          self.create_bibfile(resources["output_files_dir"]+"/"+resources["unique_key"]+".bib")
        except:
          print "error while generating bib file"
        for index, cell in enumerate(nb.cells):
            nb.cells[index], resources = self.preprocess_cell(cell, resources, index)
        return nb, resources

    def preprocess_cell(self, cell, resources, index):
        """
        Preprocess cell

        Parameters
        ----------
        cell : NotebookNode cell
            Notebook cell being processed
        resources : dictionary
            Additional resources used in the conversion process.  Allows
            preprocessors to pass variables into the Jinja engine.
        cell_index : int
            Index of the cell being processed (see base.py)
        """
        if cell.cell_type == "markdown":
            if "<div class=\"cite2c-biblio\"></div>" in cell.source:
                replaced = re.sub("<div class=\"cite2c-biblio\"></div>", r"\\bibliography{"+resources["output_files_dir"]+"/"+resources["unique_key"]+r"} \n ", cell.source)
                cell.source = replaced
        return cell, resources
