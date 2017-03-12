module Keras

using PyCall

@pyimport keras.models as models
@pyimport keras.layers as layers
@pyimport keras.optimizers as optimizers
@pyimport keras.callbacks as callbacks
@pyimport keras.backend as K

const Model = models.Model

for layer in (
    :Activation, :ActivityRegularization, :AtrousConv2D, :AtrousConvolution2D, :AveragePooling1D, :AveragePooling2D, :AveragePooling3D,
    :BatchNormalization, :Conv1D, :Conv2D, :Conv3D, :Convolution1D, :Convolution2D, :Convolution3D, :Deconv2D, :Deconvolution2D, :Dense, :Dropout,
    :ELU, :Embedding, :Flatten, :GRU, :GaussianDropout, :GaussianNoise, :Highway, :Input, :InputLayer, :InputSpec, :LSTM, :Lambda, :Layer, :LeakyReLU,
    :LocallyConnected1D, :LocallyConnected2D, :Masking, :MaxPooling1D, :MaxPooling2D, :MaxPooling3D, :MaxoutDense, :Merge, :PReLU, :ParametricSoftplus,
    :Permute, :RepeatVector, :Reshape, :SReLU, :SeparableConv2D, :SeparableConvolution2D, :SimpleRNN, :ThresholdedReLU, :TimeDistributed,
    :TimeDistributedDense, :UpSampling1D, :UpSampling2D, :UpSampling3D, :Wrapper, :ZeroPadding1D, :ZeroPadding2D, :ZeroPadding3D
)
    @eval begin
        const $layer = layers.$layer
    end
end

for optimizer in (:Adadelta, :Adagrad, :Adam, :Adamax, :Nadam, :RMSprop, :SGD)
    @eval begin
        const $optimizer = optimizers.$optimizer
    end
end

for callback in (:ProgbarLogger, :ModelCheckpoint, :EarlyStopping, :RemoteMonitor, :LearningRateScheduler)
    @eval begin
        const $callback = callbacks.$callback
    end
end

const dim_ordering = K.image_dim_ordering()

end
