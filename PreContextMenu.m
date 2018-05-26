classdef PreContextMenu
    methods(Static)
        function schemaFcns = preContextMenu
            schemaFcns = {@PreContextMenu.cocoSimActions};
        end

        function schema = cocoSimActions(callbackInfo)
            schema = sl_container_schema;
            schema.label = 'CoCoSim';
            schema.statustip = 'CoCoSim';
            schema.autoDisableWhen = 'Busy';

            modelWorkspace = get_param(callbackInfo.studio.App.blockDiagramHandle,'modelworkspace');   
            if modelWorkspace.hasVariable('compositionalMap')
                schema.childrenFcns = {...
                    @VerificationMenu.compositionalOptions,...
                    @MiscellaneousMenu.replaceInportsWithSignalBuilders...
                    };
            else
                schema.childrenFcns = {@MiscellaneousMenu.replaceInportsWithSignalBuilders};
            end
        end
    end
end