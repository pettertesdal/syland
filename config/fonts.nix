{ pkgs, ... }:

{
	fonts.packages = with pkgs; [
		nerd-fonts.proggy-clean-tt
	];
}
