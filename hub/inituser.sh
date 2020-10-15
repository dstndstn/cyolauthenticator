#! /bin/bash
echo Running inituser.sh as $USER home $HOME

cp -r /nfs/template/dot-julia ~/.julia
cp -r /nfs/template/dot-local ~/.local

# julia -e 'using Pkg; Pkg.add("IJulia")'

