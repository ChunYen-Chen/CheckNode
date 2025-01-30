name: test                                                                                                                                                                                                
 
description: File a bug fix pull request.
 
title: "[Bugfix] "
 
labels: ["bugfix"]
 
projects:
 
assignees:
 
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to fill out this bugfix report!
  - type: input
    id: bug_issue
    attributes:
      label: Bug issue number
      description: "Which bug did you solve?"
      placeholder: "Resolve #<isssue_number>"
    validations:
      required: true
  - type: textarea
    id: issue_content
    attributes:
      label: How is the bug fix?
      placeholder: Tell us how you fix the bug!
    validations:
      required: true
  - type: checkboxes
    id: labels
    attributes:
      label: Related topics
      description: You may select more than one.
      options:
        - label: Gravity
        - label: Parallel
