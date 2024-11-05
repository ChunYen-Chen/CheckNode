# How to create a bi-directional updated wiki
Before getting started, I recommend you have some basic knowledge of [repository, branch, fork](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories), [action](https://docs.github.com/en/actions), and [workflow](https://docs.github.com/en/actions/using-workflows).

The following is the outline of this document:
* [At the original repository](https://github.com/ChunYen-Chen/CheckNode/wiki/Home#at-the-original-repository)
* [At forked repository](https://github.com/ChunYen-Chen/CheckNode/wiki/Home#at-forked-repository)
* [Reference](https://github.com/ChunYen-Chen/CheckNode/wiki/Home#Reference)

## At the original repository
1. **[Optional] New branch for wiki**
   * If you want the wiki at a different branch, please create a new branch `branch_for_wiki` for the wiki.
   * Click `View all branches` to see all branches.

   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/47d2f465-7a67-47bf-bd7c-b16f13d320c9)
   * Click `New branch` to create a new branch.

   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/47f11fb5-0441-4ed7-a9c5-d3430866fdb2)

1. **Copy the `bi-directional-wiki.yaml`**
   * Cpoy the `bi-directional-wiki.yaml` under `.github/workflows`.
   ### `bi-directional-wiki.yaml`
   ```YAML
   name: Documentation

   on:
     push:
       branches:
         - branch_for_wiki
       paths:
         - "wiki_docs/**"
     repository_dispatch:
       types: [wiki_docs]
     gollum:

   env:
     GIT_AUTHOR_NAME: Actionbot
     GIT_AUTHOR_EMAIL: actions@github.com

   jobs:
     job-sync-docs-to-wiki:
       runs-on: ubuntu-latest
       if: github.event_name != 'gollum'
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
  
     job-sync-wiki-to-docs:
       runs-on: ubuntu-latest
       if: github.event_name == 'gollum'
       steps:
         - name: Checkout Repo
           uses: actions/checkout@v2
           with:
             token: ${{ secrets.TOKEN_FOR_WIKI }} # allows us to push back to repo
             ref: branch_for_wiki
         - name: Sync Wiki to Docs
           uses: newrelic/wiki-sync-action@main
           with:
             source: wiki
             destination: wiki_docs
             token: ${{ secrets.TOKEN_FOR_WIKI }}
             gitAuthorName: ${{ env.GIT_AUTHOR_NAME }}
             gitAuthorEmail: ${{ env.GIT_AUTHOR_EMAIL }}
             branch: branch_for_wiki
   ```
1. **Create a token for the action bot**
   * `Setting` of your account > `Developer setting` > `Personal access tokens` > `Generate new token`

   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/5e19015d-5ebb-46b6-9a7c-eb3fff298527)

1. **Create a repository secret token**
   * Go to `Setting` of the repository > `Security` > `Secrets and variables` > `Actions` > `Repository secrets`
   * Please check the `repo` and the `workflow` options.
   
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/1e7a7a4e-924f-442d-8f96-d48e4f1dc783)

   * Click `New repository secrets`, and then you will see the following. Please fill `TOKEN_FOR_WIKI` in the `Name` and your personal access token in `Secret`. 
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/146c4c9e-4651-47e4-919d-a3e59484222a)

1. **Update `bi-directional-wiki.yaml`**
   * Modify the `bi-directional-wiki.yaml` to match the repo, if your token name, doc directory, and the branch name are not default.

1. **Congratulations :tada:**
   * Now, you may edit the wiki on the web or push the wiki content to the `branch_for_wiki`. The wiki will be updated for both sides.

## At forked repository
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

   * Click `New repository secrets`, and then you will see the following. Please fill `TOKEN_FOR_WIKI` in the `Name` and your personal access token in `Secret`. 
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/146c4c9e-4651-47e4-919d-a3e59484222a)

1. **Enable actions**
   * Enable workflows to run in the forked repository.
   * Click `Actions` > click the green button.
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/9e58d4a8-3248-4ceb-81ff-276a6943149d)

1. **Initialize wiki**
   * If the `branch_for_wiki` is NOT forked, please add a new branch called `branch_for_wiki` and set the upstream/source properly. Once the `branch_for_wiki` is created, the wiki should also be updated.
   * If the `branch_for_wiki` is forked, please run the workflow manually. Click `Action` > `Workflows` > `Documentation` > `Run workflow` > choose `Branch: branch_for_wiki` > Click green `Run workflow`. Once the workflow is done, the wiki is also updated.
   ![image](https://github.com/ChunYen-Chen/CheckNode/assets/70311975/189376a2-c11f-4801-acc3-2656db6b31ef)

1. **Congratulations :tada:**
   * Now, you may edit the wiki on the web or push the wiki content to the `branch_for_wiki`. The wiki will be updated for both sides.

## Reference
1. [Bi-directional Wiki Sync Action](https://github.com/marketplace/actions/bi-directional-wiki-sync-action)
2. [Create Pull Requests For Your GitHub Wiki](https://nimblehq.co/blog/create-github-wiki-pull-request)
