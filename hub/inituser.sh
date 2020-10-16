#! /bin/bash
echo Running inituser.sh as $USER home $HOME

julia -e 'using Pkg; Pkg.add("IJulia")'

# This doesn't work -- those Julia packages have internal filesystem references.
#cp -r /nfs/template/dot-julia ~/.julia
#cp -r /nfs/template/dot-local ~/.local



