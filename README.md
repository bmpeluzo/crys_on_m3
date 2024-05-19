# crys_on_m3

Usage 

` chmod 777 runcrystal.sh ` 

On .bashrc (.zshrc):

` alias runcrystal='complete/path/to/runcrystal/script/' `

` source ~/.bashrc `

` runcrystal -n num_of_nodes -o job_name -p m3_queue `

To input additional files (e.g. running properties):

` runcrystal -n num_of_nodes -o job_name -p m3_queue -f 2nd_file_with_extension -e 1 `


 
