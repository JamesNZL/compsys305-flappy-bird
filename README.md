# `COMPSYS 305` Flappy Bird

An FPGA implementation of Flappy Bird, played using a PS/2 mouse, DIP switches, and push-buttons on the DE0-CV board.

## Contributing

1. Create a [new **Issue**](https://github.com/uoa-ece209/ee209-2022-project-team01/issues/new) using the Issue template

### Making Progress

2. If you are working locally, `git pull` any upstream changes
3. Create a new feature branch with an appropriate name
	> **Example**  
	> `git switch -c rc-filter`
4. Work on that branch, referencing the **Issue** in commit messages as appropriate
	> **Example**  
	> `git commit -m "feat(rc-filter): add comparator (#IssueId)"`

	> **Warning**  
	> Before you commit, ensure you `git pull`.  
	> After you commit, ensure you `git push`.
5. Once the feature is complete, `git push` your local changes

### Finishing Up

6. Open a [new **Pull Request**](https://github.com/uoa-ece209/ee209-2022-project-team01/compare) into `main` using the Pull Request template that references the `#IssueId` you are closing
	1. Assign yourself to the created **Pull Request**
	2. Request review from the other team members
7. Once all team members have approved the changes, [**squash and merge**](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges#squash-and-merge-your-pull-request-commits) with a commit message that summarises the feature
	> **Example**  
	> `feat(hardware): :sparkles: add rc filter circuit (#IssueId)`
8. Delete the feature branch
