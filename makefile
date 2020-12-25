# GitHub ========================================================================================
commit: clean
	git add -A
	@echo "Please type in commit comment: "; \
	read comment; \
	git commit -m"$$comment"
sync: commit
	git push -u origin master
# General ========================================================================================
clean:
	-rm .vscode-ctags