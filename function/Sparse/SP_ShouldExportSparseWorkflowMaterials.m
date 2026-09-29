function tf = SP_ShouldExportSparseWorkflowMaterials(params)
    tf = false;
    if ~isfield(params, 'sparse'), return; end
    if ~isfield(params.sparse, 'save_workflow_materials') || ~params.sparse.save_workflow_materials
        return;
    end
    if ~isfield(params.sparse, 'workflow_dir') || isempty(params.sparse.workflow_dir)
        return;
    end
    branch_name = '';
    if isfield(params.sparse, 'branch')
        branch_name = params.sparse.branch;
    end
    if isfield(params.sparse, 'workflow_export_branch') && ~isempty(params.sparse.workflow_export_branch)
        tf = contains(lower(branch_name), lower(params.sparse.workflow_export_branch));
    else
        tf = true;
    end
end
