# How to create a bi-directional updated wiki
Before getting started, I recommend you have some basic knowledge of [repository, branch, fork](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories), [action](https://docs.github.com/en/actions), and [workflow](https://docs.github.com/en/actions/using-workflows).

The following is the outline of this document:
* [Setup the original repository](https://github.com/ChunYen-Chen/CheckNode/wiki/New-docs#setup-the-original-repository)
* [Setup forked repository](https://github.com/ChunYen-Chen/CheckNode/wiki/New-docs#setup-forked-repository)
* [How to use it](https://github.com/ChunYen-Chen/CheckNode/wiki/New-docs/New-docs#how-to-use-it)
* [Reference](https://github.com/ChunYen-Chen/CheckNode/wiki/New-docs#Reference)

## Setup the original repository
1. **Copy `sync-doc-to-wiki.yml` and `sync-wiki-to-doc.yml`**
   * Copy `sync-doc-to-wiki.yml` and `sync-wiki-to-doc.yml` under `.github/workflows`.
   ### `sync-doc-to-wiki.yml`
   ```YAML
   name: Sync doc to wiki

   on:
     workflow_dispatch:

   env:
     GIT_AUTHOR_NAME: Actionbot
     GIT_AUTHOR_EMAIL: actions@github.com

   jobs:
     job-sync-docs-to-wiki:
       runs-on: ubuntu-latest
       steps:
         - name: Checkout Repo
           uses: actions/checkout@v2
         - name: Sync docs to wiki
           uses: newrelic/wiki-sync-action@main
           with:
             source: wiki_docs
             destination: wiki
             token: ${{ secrets.TOKEN_FOR_WIKI }}
             gitAuthorName: ${{ env.GIT_AUTHOR_NAME }}
             gitAuthorEmail: ${{ env.GIT_AUTHOR_EMAIL }}
   ```
   ### `sync-wiki-to-doc.yml`
   ```YAML
   name: Sync wiki to doc

   on:
     workflow_dispatch:

   env:
     GIT_AUTHOR_NAME: Actionbot
     GIT_AUTHOR_EMAIL: actions@github.com

   jobs:
     job-sync-wiki-to-docs:
       runs-on: ubuntu-latest
       steps:
         - name: Checkout Repo
           uses: actions/checkout@v2
           with:
             token: ${{ secrets.TOKEN_FOR_WIKI }} # allows us to push back to repo
             ref: ${{ github.ref_name }}
         - name: Sync Wiki to Docs
           uses: newrelic/wiki-sync-action@main
           with:
             source: wiki
             destination: wiki_docs
             token: ${{ secrets.TOKEN_FOR_WIKI }}
             gitAuthorName: ${{ env.GIT_AUTHOR_NAME }}
             gitAuthorEmail: ${{ env.GIT_AUTHOR_EMAIL }}
             branch: ${{ github.ref_name }}
   ```
1. **Create a token for the action bot**
   * Go to `Setting` of your account > `Developer setting` > `Personal access tokens` > `Generate new token`
   * Please check the `repo` and the `workflow` options.
   * You might want to set the `Expiration` to `No expiration`.

   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/5e19015d-5ebb-46b6-9a7c-eb3fff298527)

1. **Create a repository secret token**
   * Go to `Setting` of the repository > `Security` > `Secrets and variables` > `Actions` > `Repository secrets`
   
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/1e7a7a4e-924f-442d-8f96-d48e4f1dc783)

   * Click `New repository secrets`, and then you will see the following. Please replace `<your personal access token>` to your token at `Secret`. 

   <img width="1208" alt="Screenshot 2024-04-26 at 23 50 38" src="https://github.com/ChunYen-Chen/CheckNode/assets/70311975/adb7656b-ab65-40f5-8b25-37d302cf4e77">

1. **Congratulations :tada:**
   * You finish the setup of the bi-directional updated wiki!

## Setup forked repository
1. **Fork the repository**
   * Fork the original repository.
   
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/ce645646-e9f8-484d-8579-ac7db4c88a8b)

1. **Create first page**
   * Click the Wiki page and create the first page

   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/c48243fb-d603-4475-9949-3a088561c5c1)

1. **Create a token for the action bot**
   * `Setting` of your account > `Developer setting` > `Personal access tokens` > `Generate new token`
   * Please check the `repo` and the `workflow` options.

   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/5e19015d-5ebb-46b6-9a7c-eb3fff298527)

   * Remember to save the token since it will only be shown once!

1. **Create a repository secret token**
   * Go to `Setting` of the repository > `Security` > `Secrets and variables` > `Actions` > `Repository secrets`
   
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/1e7a7a4e-924f-442d-8f96-d48e4f1dc783)

   * Click `New repository secrets`, and then you will see the following. Please replace `<your personal access token>` to your token at `Secret`. 

   <img width="1208" alt="Screenshot 2024-04-26 at 23 50 38" src="https://github.com/ChunYen-Chen/CheckNode/assets/70311975/adb7656b-ab65-40f5-8b25-37d302cf4e77">

1. **Enable actions**
   * Enable workflows to run in the forked repository.
   * Click `Actions` > click the green button.
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/9e58d4a8-3248-4ceb-81ff-276a6943149d)

1. **Initialize wiki**
   * Click `Action` > `Workflows` > `Sync doc to wiki` > `Run workflow` > choose `Branch: master` > Click green `Run workflow`. Once the workflow is done, the wiki is also updated to the master version.

   <img width="1414" alt="Screenshot 2024-04-27 at 11 20 57" src="https://github.com/ChunYen-Chen/CheckNode/assets/70311975/2cd3d25b-160c-4fd7-8d4f-359675ed99ee">

1. **Congratulations :tada:**
   * You finish the setup of the bi-directional updated wiki at forked repository!

## How to use it
We treat the wiki page on the GitHub as a local in this method, and we use the workflow to approach the `pull` and `push` behavior of the wiki.
### Change the wiki to specific branch version
   * Click `Action` > `Workflows` > `Sync doc to wiki` > `Run workflow` > choose the specific branch > Click green `Run workflow`. Once the workflow is done, the wiki is also updated to the specific branch version.

   <img width="1414" alt="Screenshot 2024-04-27 at 11 20 57" src="https://github.com/ChunYen-Chen/CheckNode/assets/70311975/2cd3d25b-160c-4fd7-8d4f-359675ed99ee">

### Update the wiki content to specific branch
   * Click `Action` > `Workflows` > `Sync wiki to doc` > `Run workflow` > choose the specific branch > Click green `Run workflow`. Once the workflow is done, the docs in the specific branch is updated to the latest wiki.

   <img width="1416" alt="Screenshot 2024-04-27 at 11 22 00" src="https://github.com/ChunYen-Chen/CheckNode/assets/70311975/1d5482a2-8c33-41ee-bd2b-f7119924db81">

### Change the documents storage directory
The documents are stored under directory `wiki_docs` by default. If you want to store the documents under your preference directory, please replace all the `wiki_docs` in `sync-doc-to-wiki.yml` and `sync-wiki-to-doc.yml` to your directory name.

## Reference
1. [Bi-directional Wiki Sync Action](https://github.com/marketplace/actions/bi-directional-wiki-sync-action)
2. [Create Pull Requests For Your GitHub Wiki](https://nimblehq.co/blog/create-github-wiki-pull-request)
