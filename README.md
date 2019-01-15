# Overview
This repository contains weekly lecture slides, laboratory, and homework assignment. The documents can be found within the [docs](./docs) folder. The codes for your laboratory and homework can be found within the [codes](./codes) folder. Occasionally, there might be data files for your laboratory and homework, which can be found in the [data](./data) folder.

You will also use this repository to submit your reports for your laboratory and homework assignments. There are two template files within the [docs/lab](./docs/lab/) and [docs/assg](./docs/assg/) folders with name *\_\_REPORT\_\_.md*. You will write your report using these markdown files. 

To start, fill in the metadata of these files (title, author, partner, date, etc.). Write your report based on the descriptions. You can include any figures, code snippets, and other files in your git repository using [relative links](https://github.com/mark-anders/relative-image-url), and Github will automatically render them for display. For additional information on the markdown syntax, refer to the [Markdown Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).

# Accept the Repository
You can find a Github Classroom invitation to this repository by click on the week number in the course website. You should be prompted with an invitation asking you to accept the assignment. Use a Github account created under your institutional email to accept the invitation. Once accepted, Github will fork the upstream repository (the instructor's repository) and create a downstream repository under your Github account.

Clone your downstream repository to your computer use:

```
git clone "name_of_the_downstream_repo" "name_of_the_local_folder"
```

This will generate a local repository on your computer. 

# Update the Repository

You can add additional files to the repository as needed. Stage and commit your changes use:

```
git add -A && git commit -m "YOUR message" && git push
```

This will update both the repository in your computer and in your Github account. You make any changes before the deadline passes.

Occasionally, the instructor might update the repository. You can sync with the upstream repository use:

```
git fetch upstream && git merge upstream/master
```

Additional information on Git can be found [here](https://guides.github.com/)
# Submit the Repository
Before you submit your repository for grading. Make sure the *\_\_REPORT\_\_.md* files are rendered correctly in your web browser, and all items are visible. Make a final commit to submit your work.
